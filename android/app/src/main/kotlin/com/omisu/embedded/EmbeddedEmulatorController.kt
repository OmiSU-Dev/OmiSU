package com.omisu.embedded

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import androidx.lifecycle.LifecycleOwner
import com.omisu.streaming.EmbeddedStreamCapture
import com.swordfish.libretrodroid.GLRetroView
import com.swordfish.libretrodroid.GLRetroViewData
import com.swordfish.libretrodroid.ImmersiveMode
import com.swordfish.libretrodroid.LibretroDroid
import com.swordfish.libretrodroid.Variable
import java.io.File
import java.util.Locale
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout

data class EmbeddedCheatEntry(
    val code: String,
    val enabled: Boolean,
)

data class LaunchTuning(
    val skipDuplicateFrames: Boolean = true,
    val preferLowLatencyAudio: Boolean = true,
    val rumbleEventsEnabled: Boolean = true,
    val variables: Map<String, String> = emptyMap(),
    val cheats: List<EmbeddedCheatEntry> = emptyList(),
    val shaderFilter: String = "auto",
    val hdMode: Boolean = false,
    val hdModeQuality: EmbeddedHdModeQuality = EmbeddedHdModeQuality.MEDIUM,
    val adaptiveHdMode: Boolean = true,
    val immersiveMode: Boolean = false,
    val autosaveOnExit: Boolean = true,
)

class EmbeddedEmulatorController {
    private var retroView: GLRetroView? = null
    private var coreName: String? = null
    private var romBase: String? = null
    private var appContext: android.content.Context? = null
    private var hostActivity: Activity? = null
    private var autosaveOnExit: Boolean = true
    private var audioEnabled: Boolean = true
    private var frameSpeed: Int = 1

    /** True while the in-game menu is holding emulation on the current frame. */
    private var menuPaused = false
    private var rumbleLooper: EmbeddedRumbleLooper? = null
    private var frameMetricsJob: Job? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var presentationNudgeGeneration = 0
    private var lastPresentationNudgeAt = 0L
    private var fpsCounterEnabled: Boolean = false
    private var autosaveRestoreJob: Job? = null
    private var postFirstFrameJob: Job? = null
    private var adaptiveGovernor: EmbeddedAdaptiveHdGovernor? = null
    private var effectiveHdQuality: EmbeddedHdModeQuality = EmbeddedHdModeQuality.MEDIUM
    private var activeSystemId: String? = null
    private var displayTuning: LaunchTuning = LaunchTuning()
    private var pendingCheats: List<EmbeddedCheatEntry> = emptyList()
    private var preparedRom: ResolvedRom? = null
    private var preparedRomSourcePath: String? = null
    private var viewDetached: Boolean = false

    /** When false, gamepad keys and stick motion are not sent to the core (Flutter UI). */
    private var routeGamepadToCore: Boolean = true

    fun setRouteGamepadToCore(enabled: Boolean) {
        routeGamepadToCore = enabled
        Log.i(TAG, "routeGamepadToCore=$enabled")
    }

    /**
     * Downloads the core, PPSSPP system assets when needed, and resolves the ROM
     * on a background thread before the PlatformView is created.
     */
    fun prepareLaunch(
        context: android.content.Context,
        systemId: String,
        romPath: String,
    ) {
        preparedRom = null
        preparedRomSourcePath = null

        val mapping =
            CoreMappingRegistry.forSystem(systemId)
                ?: throw IllegalArgumentException("No embedded core for system: $systemId")

        CoreResolver.resolve(context, mapping)

        if (mapping.coreName == "ppsspp") {
            PpssppAssetsManager.ensureAssets(context)
        }

        val resolvedRom = CoreResolver.resolveRomForPlay(context, romPath)
        preparedRom = resolvedRom
        preparedRomSourcePath = romPath
    }

    fun createRetroView(
        activity: Activity,
        systemId: String,
        romPath: String,
        tuning: LaunchTuning = LaunchTuning(),
    ): GLRetroView {
        EmbeddedCoreGate.awaitCoreIdle()

        val staleView = retroView
        if (staleView != null) {
            val owner = activity as? LifecycleOwner
            if (owner != null) {
                Log.w(TAG, "createRetroView found stale GLRetroView; tearing down first")
                detachRetroView(owner, staleView, flushAutosave = false)
            } else {
                clearRetroViewReference()
                clearNonViewSessionState()
            }
        }
        viewDetached = false

        val effectiveTuning = EmbeddedSystemTuningRegistry.merge(tuning, systemId)

        val mapping =
            CoreMappingRegistry.forSystem(systemId)
                ?: throw IllegalArgumentException("No embedded core for system: $systemId")

        val coreFile = CoreResolver.resolve(activity, mapping)
        if (!coreFile.exists() || coreFile.length() == 0L) {
            throw IllegalStateException(
                "Core ${mapping.libretroFileName} is missing or empty at ${coreFile.absolutePath}",
            )
        }

        val resolvedRom =
            if (preparedRomSourcePath == romPath && preparedRom != null) {
                preparedRom!!
            } else {
                if (mapping.coreName == "ppsspp") {
                    PpssppAssetsManager.ensureAssets(activity)
                }
                CoreResolver.resolveRomForPlay(activity, romPath)
            }
        preparedRom = null
        preparedRomSourcePath = null
        val romBaseName = EmbeddedSavesManager.romBaseName(resolvedRom.displayName)

        coreName = mapping.coreName
        romBase = romBaseName
        activeSystemId = systemId
        displayTuning = effectiveTuning
        pendingCheats = emptyList()
        appContext = activity.applicationContext
        hostActivity = activity
        autosaveOnExit = effectiveTuning.autosaveOnExit
        audioEnabled = true
        frameSpeed = 1
        menuPaused = false

        Log.i(
            TAG,
            "Launching embedded $systemId core=${mapping.coreName} " +
                "coreBytes=${coreFile.length()} rom=${resolvedRom.displayName} " +
                "path=${resolvedRom.gameFilePath} hdMode=${effectiveTuning.hdMode} " +
                "hdQuality=${effectiveTuning.hdModeQuality} " +
                "shader=${effectiveTuning.shaderFilter} " +
                "skipDup=${effectiveTuning.skipDuplicateFrames}",
        )
        EmbeddedLaunchTrace.event(
            "native_launch",
            "system=$systemId core=${mapping.coreName} hd=${effectiveTuning.hdMode} " +
                "hdQ=${effectiveTuning.hdModeQuality} shader=${effectiveTuning.shaderFilter} " +
                "skipDup=${effectiveTuning.skipDuplicateFrames}",
        )

        val data =
            GLRetroViewData(activity).apply {
                coreFilePath = coreFile.absolutePath
                gameFilePath = resolvedRom.gameFilePath
                savesDirectory = EmbeddedSavesManager.sramRoot(activity).absolutePath
                systemDirectory =
                    File(activity.filesDir, "omisu/system").apply { mkdirs() }.absolutePath
                rumbleEventsEnabled = effectiveTuning.rumbleEventsEnabled
                skipDuplicateFrames = effectiveTuning.skipDuplicateFrames
                preferLowLatencyAudio = effectiveTuning.preferLowLatencyAudio
                shader =
                    EmbeddedShaderChooser.shaderFor(
                        activity,
                        systemId,
                        effectiveTuning.shaderFilter,
                        effectiveTuning.hdMode,
                        effectiveTuning.hdModeQuality,
                    )
                if (effectiveTuning.immersiveMode) {
                    immersiveMode = ImmersiveMode(blendFactor = 0.05f)
                }
                variables =
                    effectiveTuning.variables.entries
                        .map { (key, value) -> Variable(key, value) }
                        .toTypedArray()
            }

        val view =
            GLRetroView(activity, data).apply {
                isFocusable = true
                isFocusableInTouchMode = true
                this.audioEnabled = audioEnabled
            }
        retroView = view
        EmbeddedStreamCapture.register(view)
        if (effectiveTuning.rumbleEventsEnabled) {
            rumbleLooper =
                EmbeddedRumbleLooper(activity.applicationContext).also { it.start(view) }
        }
        scheduleErrorMonitoring(view)
        schedulePostFirstFrameTasks(view)
        configureAdaptiveHd(activity, systemId, effectiveTuning)
        restartFrameMetrics(view)
        return view
    }

    @OptIn(DelicateCoroutinesApi::class)
    private fun scheduleErrorMonitoring(view: GLRetroView) {
        GlobalScope.launch {
            view.getGLRetroErrors().collect { code ->
                Log.e(TAG, "GLRetro error code=$code for rom=$romBase")
                EmbeddedLaunchTrace.event("gl_error", "code=$code rom=$romBase")
                CoreResolver.statusListener?.invoke("error:$code")
            }
        }
    }

    fun setFpsCounterEnabled(enabled: Boolean) {
        fpsCounterEnabled = enabled
        val view = retroView ?: return
        restartFrameMetrics(view)
    }

    @OptIn(DelicateCoroutinesApi::class)
    private fun restartFrameMetrics(view: GLRetroView) {
        stopFrameMetrics()
        if (!fpsCounterEnabled && !shouldRunAdaptiveGovernor()) return

        frameMetricsJob =
            GlobalScope.launch {
                var frameCount = 0
                var windowStart = System.nanoTime()
                view.getGLRetroEvents().collect { event ->
                    if (event !is GLRetroView.GLRetroEvents.FrameRendered) return@collect
                    frameCount++
                    val now = System.nanoTime()
                    val elapsedMs = (now - windowStart) / 1_000_000.0
                    if (elapsedMs < EmbeddedAdaptiveHdGovernor.WINDOW_MS) return@collect
                    val fps = frameCount * 1000.0 / elapsedMs
                    frameCount = 0
                    windowStart = now
                    if (fpsCounterEnabled) {
                        CoreResolver.statusListener?.invoke(
                            "fps:${String.format(Locale.US, "%.1f", fps)}",
                        )
                    }
                    adaptiveGovernor?.onFpsWindow(fps)
                }
            }
    }

    private fun stopFrameMetrics() {
        frameMetricsJob?.cancel()
        frameMetricsJob = null
    }

    private fun shouldRunAdaptiveGovernor(): Boolean =
        displayTuning.hdMode && displayTuning.adaptiveHdMode

    private fun configureAdaptiveHd(
        context: android.content.Context,
        systemId: String,
        tuning: LaunchTuning,
    ) {
        adaptiveGovernor = null
        if (!tuning.hdMode || !tuning.adaptiveHdMode) {
            effectiveHdQuality = tuning.hdModeQuality
            applyEffectiveShader()
            return
        }

        val startQuality =
            EmbeddedAdaptiveHdStore.resolveStartQuality(
                context,
                systemId,
                tuning.hdModeQuality,
            )
        effectiveHdQuality = startQuality
        adaptiveGovernor =
            EmbeddedAdaptiveHdGovernor(
                userCeiling = tuning.hdModeQuality,
                startQuality = startQuality,
                onQualityChanged = { quality ->
                    effectiveHdQuality = quality
                    val ctx = appContext
                    val sid = activeSystemId
                    if (ctx != null && sid != null) {
                        EmbeddedAdaptiveHdStore.set(ctx, sid, quality)
                    }
                    applyEffectiveShader()
                    CoreResolver.statusListener?.invoke(
                        "hdQuality:${quality.name.lowercase()}",
                    )
                    Log.i(TAG, "Adaptive HD quality -> $quality for $sid")
                },
            )
        applyEffectiveShader()
        if (startQuality < tuning.hdModeQuality) {
            CoreResolver.statusListener?.invoke(
                "hdQuality:${startQuality.name.lowercase()}",
            )
        }
    }

    private fun applyEffectiveShader() {
        val view = retroView ?: return
        val ctx = appContext ?: return
        val systemId = activeSystemId ?: return
        val hdQuality =
            if (displayTuning.hdMode) {
                effectiveHdQuality
            } else {
                displayTuning.hdModeQuality
            }
        view.shader =
            EmbeddedShaderChooser.shaderFor(
                ctx,
                systemId,
                displayTuning.shaderFilter,
                displayTuning.hdMode,
                hdQuality,
            )
    }

    @OptIn(DelicateCoroutinesApi::class)
    private fun schedulePostFirstFrameTasks(view: GLRetroView) {
        postFirstFrameJob?.cancel()
        autosaveRestoreJob?.cancel()
        postFirstFrameJob =
            GlobalScope.launch {
                waitForFirstFrame(view)
                applyPendingCheats(view)
                if (autosaveOnExit) {
                    val ctx = appContext ?: return@launch
                    val core = coreName ?: return@launch
                    val rom = romBase ?: return@launch
                    if (EmbeddedSavesCoherency.shouldDiscardAutosave(ctx, core, rom)) {
                        Log.i(
                            TAG,
                            "Skipping autosave restore for $rom: SRAM is newer than autosave",
                        )
                        return@launch
                    }
                    restoreAutosaveWithRetry(view, ctx, core, rom)
                }
            }
        autosaveRestoreJob = postFirstFrameJob
    }

    @OptIn(DelicateCoroutinesApi::class)
    private suspend fun waitForFirstFrame(view: GLRetroView) {
        repeat(FRAME_WAIT_ATTEMPTS) { attempt ->
            try {
                withTimeout(FRAME_WAIT_TIMEOUT_MS) {
                    view.getGLRetroEvents().first {
                        it is GLRetroView.GLRetroEvents.FrameRendered
                    }
                }
                val activity = hostActivity
                view.post {
                    CoreResolver.statusListener?.invoke("presenting")
                    nudgePresentation(view, force = true)
                    if (activity != null) {
                        EmbeddedPresentation.syncHybridCompositor(activity, view)
                    }
                }
                Log.i(TAG, "First frame rendered for rom=$romBase")
                EmbeddedLaunchTrace.event("first_frame", "rom=$romBase")
                return
            } catch (e: Exception) {
                Log.w(TAG, "Frame wait attempt ${attempt + 1} failed: $e")
                delay(FRAME_WAIT_RETRY_MS)
            }
        }
    }

    private suspend fun restoreAutosaveWithRetry(
        view: GLRetroView,
        context: android.content.Context,
        coreName: String,
        romBase: String,
    ) {
        val autosave = EmbeddedSavesManager.autosaveFile(context, coreName, romBase)
        if (!autosave.exists() || autosave.length() == 0L) return
        val bytes = autosave.readBytes()
        repeat(STATE_RESTORE_ATTEMPTS) { attempt ->
            val loaded =
                runCatching { view.unserializeState(bytes) }
                    .onFailure { error ->
                        Log.w(
                            TAG,
                            "Autosave restore attempt ${attempt + 1} failed for $romBase: $error",
                        )
                    }
                    .getOrDefault(false)
            if (loaded) {
                Log.i(TAG, "Autosave restored for $romBase")
                return
            }
            delay(STATE_RESTORE_RETRY_MS)
        }
        Log.w(TAG, "Autosave restore exhausted retries for $romBase")
    }

    fun saveState(slot: Int = 1): Boolean {
        val view = retroView ?: return false
        val ctx = appContext ?: return false
        val core = coreName ?: return false
        val rom = romBase ?: return false
        val bytes = view.serializeState(false) ?: return false
        val dest =
            if (slot == 0) {
                EmbeddedSavesManager.autosaveFile(ctx, core, rom)
            } else {
                EmbeddedSavesManager.slotFile(ctx, core, rom, slot)
            }
        EmbeddedSavesManager.writeBytesAtomic(dest, bytes)
        if (slot in 1..EmbeddedSavesManager.MAX_SLOTS) {
            runCatching { capturePreview(view, ctx, core, rom, slot) }
        }
        return true
    }

    private fun capturePreview(
        view: GLRetroView,
        context: android.content.Context,
        core: String,
        rom: String,
        slot: Int,
    ) {
        // LibretroDroid 0.13.2 has no takeScreenshot API; previews are optional.
    }

    fun loadState(slot: Int = 1): Boolean {
        val view = retroView ?: return false
        val ctx = appContext ?: return false
        val core = coreName ?: return false
        val rom = romBase ?: return false
        val file =
            if (slot == 0) {
                EmbeddedSavesManager.autosaveFile(ctx, core, rom)
            } else {
                EmbeddedSavesManager.slotFile(ctx, core, rom, slot)
            }
        if (!file.exists() || file.length() == 0L) return false
        val bytes = file.readBytes()
        return runCatching { view.unserializeState(bytes) }
            .onFailure { Log.w(TAG, "loadState slot=$slot failed for $rom: $it") }
            .getOrDefault(false)
    }

    fun hasStateSlot(slot: Int): Boolean {
        val ctx = appContext ?: return false
        val core = coreName ?: return false
        val rom = romBase ?: return false
        val file =
            if (slot == 0) {
                EmbeddedSavesManager.autosaveFile(ctx, core, rom)
            } else {
                EmbeddedSavesManager.slotFile(ctx, core, rom, slot)
            }
        return file.exists() && file.length() > 0L
    }

    fun getStatePreviewBytes(slot: Int): ByteArray? {
        if (slot !in 1..EmbeddedSavesManager.MAX_SLOTS) return null
        val ctx = appContext ?: return null
        val core = coreName ?: return null
        val rom = romBase ?: return null
        val file = EmbeddedSavesManager.previewFile(ctx, core, rom, slot)
        if (!file.exists() || file.length() == 0L) return null
        return file.readBytes()
    }

    fun getCoreVariables(): List<Map<String, String?>> {
        val view = retroView ?: return emptyList()
        return view.getVariables().mapNotNull { variable ->
            val key = variable.key ?: return@mapNotNull null
            mapOf(
                "key" to key,
                "value" to variable.value,
                "description" to variable.description,
            )
        }
    }

    fun applyCheats(entries: List<EmbeddedCheatEntry>) {
        pendingCheats = entries
        val view = retroView ?: return
        GlobalScope.launch {
            waitForFirstFrame(view)
            applyCheatsOnView(view, entries)
        }
    }

    fun setCheatAtIndex(index: Int, enabled: Boolean, code: String) {
        if (code.isBlank()) return
        val updated = pendingCheats.toMutableList()
        if (index in updated.indices) {
            updated[index] = EmbeddedCheatEntry(code = code, enabled = enabled)
        } else {
            while (updated.size < index) {
                updated.add(EmbeddedCheatEntry(code = "", enabled = false))
            }
            updated.add(EmbeddedCheatEntry(code = code, enabled = enabled))
        }
        pendingCheats = updated
        val view = retroView ?: return
        applyCheatsOnView(view, updated)
    }

    private fun applyPendingCheats(view: GLRetroView) {
        if (pendingCheats.isEmpty()) return
        applyCheatsOnView(view, pendingCheats)
    }

    /**
     * Clears libretro cheat state, then enables only [EmbeddedCheatEntry.enabled] slots
     * (stable index per list position). Disabling requires reset — toggling enable alone
     * does not reliably undo patches on all cores.
     */
    private fun applyCheatsOnView(view: GLRetroView, entries: List<EmbeddedCheatEntry>) {
        view.queueEvent {
            runCatching {
                LibretroDroid.resetCheat()
                var applied = 0
                entries.forEachIndexed { index, entry ->
                    val code = entry.code.trim()
                    if (code.isEmpty() || !entry.enabled) return@forEachIndexed
                    LibretroDroid.setCheat(index, true, code)
                    applied++
                }
                Log.i(TAG, "Cheats active: $applied of ${entries.size} defined")
            }.onFailure { e ->
                Log.w(TAG, "applyCheats failed: $e")
            }
        }
    }

    fun updateCoreVariable(key: String, value: String): Boolean {
        val view = retroView ?: return false
        if (key.isBlank()) return false
        return runCatching {
            view.updateVariables(Variable(key, value))
            true
        }.getOrDefault(false)
    }

    fun flushSram(): Boolean {
        val view = retroView ?: return false
        val ctx = appContext ?: return false
        val core = coreName ?: return false
        val rom = romBase ?: return false
        val bytes = view.serializeSRAM() ?: return false
        // Match libretro's flat saves path so coherency sees in-game battery writes.
        val dest = EmbeddedSavesManager.libretroSramFile(ctx, rom)
        EmbeddedSavesManager.writeBytesAtomic(dest, bytes)
        return true
    }

    fun setAudioEnabled(enabled: Boolean) {
        audioEnabled = enabled
        retroView?.audioEnabled = enabled
    }

    fun isAudioEnabled(): Boolean = audioEnabled

    fun setFastForward(enabled: Boolean) {
        frameSpeed = if (enabled) 2 else 1
        retroView?.frameSpeed = frameSpeed
    }

    /**
     * Freezes the core on the current frame while the in-game menu is open.
     * The surface keeps that frame on screen. The view's own pause stays with
     * the activity lifecycle so the picture does not go black.
     */
    /**
     * Re-sync hybrid-composition layout after the GL surface starts presenting.
     * Does not recreate the PlatformView (unlike Flutter setState refresh loops).
     */
    fun nudgePresentation() {
        val view = retroView ?: return
        nudgePresentation(view, force = false)
    }

    private fun nudgePresentation(view: GLRetroView, force: Boolean) {
        val now = System.currentTimeMillis()
        if (!force && now - lastPresentationNudgeAt < PRESENTATION_NUDGE_COOLDOWN_MS) {
            return
        }
        lastPresentationNudgeAt = now
        presentationNudgeGeneration++
        val generation = presentationNudgeGeneration
        EmbeddedLaunchTrace.event("presentation_nudge", "gen=$generation")
        view.post {
            if (retroView !== view || viewDetached) return@post
            view.requestLayout()
            view.invalidate()
            view.requestRender()
        }
        for (delayMs in PRESENTATION_NUDGE_DELAYS_MS) {
            mainHandler.postDelayed(
                {
                    if (generation != presentationNudgeGeneration) return@postDelayed
                    if (retroView !== view || viewDetached) return@postDelayed
                    view.requestRender()
                    view.invalidate()
                },
                delayMs,
            )
        }
    }

    fun setEmulationPaused(paused: Boolean) {
        val view = retroView ?: return
        EmbeddedLaunchTrace.event(
            if (paused) "emulation_paused" else "emulation_resumed",
            "menuPaused=$menuPaused rom=$romBase",
        )
        if (paused) {
            // Re-apply even if already paused. Returning from the home screen
            // resumes the core from the activity lifecycle while the menu is
            // still open.
            menuPaused = true
            setEmulationReady(view, false)
            view.queueEvent {
                runCatching { LibretroDroid.pause() }
                    .onFailure { Log.w(TAG, "LibretroDroid.pause failed: $it") }
            }
            return
        }
        if (!menuPaused) return
        menuPaused = false
        val restoreAudio = audioEnabled
        val restoreSpeed = frameSpeed
        view.queueEvent {
            runCatching {
                LibretroDroid.resume()
                // resume() restarts the audio device. Put mute and fast-forward
                // back the way the player left them.
                LibretroDroid.setAudioEnabled(restoreAudio)
                LibretroDroid.setFrameSpeed(restoreSpeed)
            }.onFailure { Log.w(TAG, "LibretroDroid.resume failed: $it") }
            setEmulationReady(view, true)
        }
    }

    private fun setEmulationReady(view: GLRetroView, ready: Boolean) {
        runCatching {
            val field = GLRetroView::class.java.getDeclaredField("isEmulationReady")
            field.isAccessible = true
            field.setBoolean(view, ready)
        }.onFailure {
            Log.w(TAG, "Could not set emulation ready=$ready: $it")
        }
    }

    fun isFastForward(): Boolean = frameSpeed > 1

    fun applyDisplaySettings(
        systemId: String,
        shaderFilter: String,
        hdMode: Boolean,
        hdModeQuality: EmbeddedHdModeQuality = displayTuning.hdModeQuality,
        adaptiveHdMode: Boolean = displayTuning.adaptiveHdMode,
    ) {
        val tuning =
            displayTuning.copy(
                shaderFilter = shaderFilter,
                hdMode = hdMode,
                hdModeQuality = hdModeQuality,
                adaptiveHdMode = adaptiveHdMode,
            )
        displayTuning = tuning
        activeSystemId = systemId
        val ctx = appContext
        if (ctx != null) {
            configureAdaptiveHd(ctx, systemId, tuning)
        } else {
            effectiveHdQuality = hdModeQuality
            applyEffectiveShader()
        }
        retroView?.let { restartFrameMetrics(it) }
        Log.i(
            TAG,
            "Applied display settings for $systemId hdMode=$hdMode " +
                "hdQuality=$hdModeQuality adaptive=$adaptiveHdMode shader=$shaderFilter",
        )
    }

    fun reset() {
        retroView?.reset()
    }

    fun sendKeyEvent(action: Int, keyCode: Int, port: Int = 0) {
        retroView?.sendKeyEvent(action, keyCode, port)
    }

    fun handleKeyEvent(event: KeyEvent): Boolean {
        val view = retroView ?: return false
        if (event.keyCode !in EmbeddedGamepadMapper.gamepadKeys) return false
        if (!routeGamepadToCore) return false
        // Start is reserved for opening the in-game pause menu in Flutter.
        if (event.keyCode == KeyEvent.KEYCODE_BUTTON_START) return false
        val port = playerPort(event)
        val mapped = EmbeddedGamepadMapper.mapKeyCode(event.keyCode)
        view.sendKeyEvent(event.action, mapped, port)
        return true
    }

    fun handleMotionEvent(event: MotionEvent): Boolean {
        val view = retroView ?: return false
        if (!routeGamepadToCore) return false
        val isGamepadMotion =
            (event.source and InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK ||
                (event.source and InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
        if (!isGamepadMotion) return false
        if (event.action != MotionEvent.ACTION_MOVE) return true
        val port = playerPort(event)
        EmbeddedGamepadMapper.sendStickMotions(view, event, port)
        return true
    }

    private fun playerPort(event: KeyEvent): Int = playerPort(event.device?.controllerNumber)

    private fun playerPort(event: MotionEvent): Int = playerPort(event.device?.controllerNumber)

    /** Embedded play is single-player; treat unknown controller ids as port 0. */
    private fun playerPort(controllerNumber: Int?): Int {
        val number = controllerNumber ?: 0
        return if (number > 0) number - 1 else 0
    }

    fun isViewDetached(view: GLRetroView): Boolean =
        viewDetached || retroView == null || retroView !== view

    fun unload(activity: Activity, flushAutosave: Boolean = true) {
        val owner = activity as? LifecycleOwner
        val view = retroView
        if (view != null && owner != null) {
            detachRetroView(owner, view, flushAutosave)
        } else {
            dispose(flushAutosave)
        }
    }

    fun detachRetroView(
        lifecycleOwner: LifecycleOwner,
        view: GLRetroView,
        flushAutosave: Boolean,
    ) {
        if (isViewDetached(view)) {
            if (flushAutosave) {
                flushSessionState(flushAutosave)
            }
            clearNonViewSessionState()
            return
        }
        EmbeddedLaunchTrace.event("detach_view", "core=$coreName rom=$romBase flush=$flushAutosave")
        stopFrameMetrics()
        adaptiveGovernor = null
        autosaveRestoreJob?.cancel()
        autosaveRestoreJob = null
        postFirstFrameJob?.cancel()
        postFirstFrameJob = null
        rumbleLooper?.stop()
        rumbleLooper = null
        val core = coreName
        EmbeddedCoreGate.teardown(view, core) {
            flushSessionState(flushAutosave)
        }
        viewDetached = true
        clearRetroViewReference()
        clearNonViewSessionState()
    }

    fun dispose(flushAutosave: Boolean = true) {
        stopFrameMetrics()
        adaptiveGovernor = null
        autosaveRestoreJob?.cancel()
        autosaveRestoreJob = null
        postFirstFrameJob?.cancel()
        postFirstFrameJob = null
        rumbleLooper?.stop()
        rumbleLooper = null
        flushSessionState(flushAutosave)
        clearRetroViewReference()
        viewDetached = false
        clearNonViewSessionState()
        EmbeddedCoreGate.resetSession()
    }

    private fun flushSessionState(flushAutosave: Boolean) {
        if (flushAutosave && autosaveOnExit) {
            runCatching { saveState(slot = 0) }
            runCatching { flushSram() }
        }
    }

    private fun clearRetroViewReference() {
        EmbeddedStreamCapture.unregister(retroView)
        retroView = null
    }

    private fun clearNonViewSessionState() {
        coreName = null
        romBase = null
        menuPaused = false
        activeSystemId = null
        appContext = null
        hostActivity = null
        preparedRom = null
        preparedRomSourcePath = null
    }

    companion object {
        private const val TAG = "EmbeddedEmulator"
        private const val PREVIEW_MAX_PX = 240
        private const val FRAME_WAIT_ATTEMPTS = 10
        private const val FRAME_WAIT_TIMEOUT_MS = 3_000L
        private const val FRAME_WAIT_RETRY_MS = 100L
        private val PRESENTATION_NUDGE_DELAYS_MS = longArrayOf(50L, 150L, 400L)
        private const val PRESENTATION_NUDGE_COOLDOWN_MS = 750L
        private const val STATE_RESTORE_ATTEMPTS = 10
        private const val STATE_RESTORE_RETRY_MS = 200L

        fun parseBool(value: Any?): Boolean =
            when (value) {
                is Boolean -> value
                is Number -> value.toInt() != 0
                is String -> value.equals("true", ignoreCase = true)
                else -> false
            }

        @Suppress("UNCHECKED_CAST")
        fun parseTuning(creationParams: Map<String, Any>?): LaunchTuning {
            val raw = creationParams?.get("tuning") as? Map<String, Any> ?: return LaunchTuning()
            val variables =
                (raw["variables"] as? Map<String, Any>)?.mapNotNull { (key, value) ->
                    value?.toString()?.let { key to it }
                }?.toMap() ?: emptyMap()
            val cheats =
                (raw["cheats"] as? List<*>)?.mapNotNull { item ->
                    val map = item as? Map<String, Any> ?: return@mapNotNull null
                    val code = map["code"]?.toString()?.trim() ?: return@mapNotNull null
                    if (code.isEmpty()) return@mapNotNull null
                    EmbeddedCheatEntry(
                        code = code,
                        enabled = parseBool(map["enabled"]),
                    )
                } ?: emptyList()
            return LaunchTuning(
                skipDuplicateFrames =
                    if (raw.containsKey("skipDuplicateFrames")) {
                        parseBool(raw["skipDuplicateFrames"])
                    } else {
                        true
                    },
                preferLowLatencyAudio =
                    if (raw.containsKey("preferLowLatencyAudio")) {
                        parseBool(raw["preferLowLatencyAudio"])
                    } else {
                        true
                    },
                rumbleEventsEnabled =
                    if (raw.containsKey("rumbleEventsEnabled")) {
                        parseBool(raw["rumbleEventsEnabled"])
                    } else {
                        true
                    },
                variables = variables,
                cheats = cheats,
                shaderFilter = raw["shaderFilter"]?.toString() ?: "auto",
                hdMode = parseBool(raw["hdMode"]),
                hdModeQuality = EmbeddedHdModeQuality.parse(raw["hdModeQuality"]),
                adaptiveHdMode =
                    if (raw.containsKey("adaptiveHdMode")) {
                        parseBool(raw["adaptiveHdMode"])
                    } else {
                        true
                    },
                immersiveMode = parseBool(raw["immersiveMode"]),
                autosaveOnExit =
                    if (raw.containsKey("autosaveOnExit")) {
                        parseBool(raw["autosaveOnExit"])
                    } else {
                        true
                    },
            )
        }
    }
}
