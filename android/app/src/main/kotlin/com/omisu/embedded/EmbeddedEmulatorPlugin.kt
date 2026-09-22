package com.omisu.embedded

import android.app.Activity
import android.content.Context
import android.hardware.input.InputManager
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class EmbeddedEmulatorPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {
    private val controller = EmbeddedEmulatorController()
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var keyListener: ((KeyEvent) -> Boolean)? = null
    private var motionListener: ((MotionEvent) -> Boolean)? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel =
            MethodChannel(binding.binaryMessenger, CHANNEL).also {
                it.setMethodCallHandler(this)
            }
        eventChannel =
            EventChannel(binding.binaryMessenger, EVENT_CHANNEL).also {
                it.setStreamHandler(
                    object : EventChannel.StreamHandler {
                        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                            eventSink = events
                        }

                        override fun onCancel(arguments: Any?) {
                            eventSink = null
                        }
                    },
                )
            }
        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            EmbeddedRetroViewFactory(controller) { activity },
        )
        CoreResolver.statusListener = listener@{ message ->
            val sink = eventSink ?: return@listener
            val payload =
                mapOf(
                    "type" to "status",
                    "message" to message,
                )
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                sink.success(payload)
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CoreResolver.statusListener = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        controller.dispose()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "saveState" -> {
                    val slot = call.argument<Int>("slot") ?: 1
                    result.success(controller.saveState(slot))
                }
                "loadState" -> {
                    val slot = call.argument<Int>("slot") ?: 1
                    result.success(controller.loadState(slot))
                }
                "setAudioEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    controller.setAudioEnabled(enabled)
                    result.success(true)
                }
                "setFastForward" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    controller.setFastForward(enabled)
                    result.success(true)
                }
                "setEmulationPaused" -> {
                    val paused = call.argument<Boolean>("paused") ?: false
                    controller.setEmulationPaused(paused)
                    result.success(true)
                }
                "nudgePresentation" -> {
                    controller.nudgePresentation()
                    result.success(true)
                }
                "setRouteGamepadToCore" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    controller.setRouteGamepadToCore(enabled)
                    result.success(true)
                }
                "setFpsCounterEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    controller.setFpsCounterEnabled(enabled)
                    result.success(true)
                }
                "applyDisplaySettings" -> {
                    val systemId = call.argument<String>("systemId")
                    if (systemId.isNullOrBlank()) {
                        result.error("invalid_args", "systemId is required", null)
                        return
                    }
                    val shaderFilter = call.argument<String>("shaderFilter") ?: "auto"
                    val hdMode = EmbeddedEmulatorController.parseBool(call.argument<Any>("hdMode"))
                    val hdModeQuality =
                        EmbeddedHdModeQuality.parse(call.argument<Any>("hdModeQuality"))
                    val adaptiveHdMode =
                        EmbeddedEmulatorController.parseBool(call.argument<Any>("adaptiveHdMode"))
                    controller.applyDisplaySettings(
                        systemId,
                        shaderFilter,
                        hdMode,
                        hdModeQuality,
                        adaptiveHdMode,
                    )
                    result.success(true)
                }
                "isAudioEnabled" -> result.success(controller.isAudioEnabled())
                "isFastForward" -> result.success(controller.isFastForward())
                "hasStateSlot" -> {
                    val slot = call.argument<Int>("slot") ?: 1
                    result.success(controller.hasStateSlot(slot))
                }
                "getStatePreview" -> {
                    val slot = call.argument<Int>("slot") ?: 1
                    result.success(controller.getStatePreviewBytes(slot))
                }
                "getCoreVariables" -> {
                    result.success(controller.getCoreVariables())
                }
                "updateCoreVariable" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key.isNullOrBlank() || value == null) {
                        result.error("invalid_args", "key and value are required", null)
                        return
                    }
                    result.success(controller.updateCoreVariable(key, value))
                }
                "applyCheats" -> {
                    val raw = call.argument<List<Map<String, Any?>>>("cheats") ?: emptyList()
                    val entries =
                        raw.mapNotNull { map ->
                            val code = map["code"]?.toString()?.trim() ?: return@mapNotNull null
                            if (code.isEmpty()) return@mapNotNull null
                            EmbeddedCheatEntry(
                                code = code,
                                enabled = EmbeddedEmulatorController.parseBool(map["enabled"]),
                            )
                        }
                    controller.applyCheats(entries)
                    result.success(true)
                }
                "setCheatEnabled" -> {
                    val index = call.argument<Int>("index") ?: 0
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val code = call.argument<String>("code") ?: ""
                    if (code.isBlank()) {
                        result.error("invalid_args", "code is required", null)
                        return
                    }
                    controller.setCheatAtIndex(index, enabled, code)
                    result.success(true)
                }
                "reset" -> {
                    controller.reset()
                    result.success(true)
                }
                "unload" -> {
                    val act = activity
                    if (act != null) {
                        controller.unload(act, flushAutosave = true)
                    } else {
                        controller.dispose(flushAutosave = true)
                    }
                    result.success(true)
                }
                "ensureCoreIdle" -> {
                    EmbeddedCoreGate.awaitCoreIdle()
                    result.success(true)
                }
                "sendKeyEvent" -> {
                    val action = call.argument<Int>("action") ?: KeyEvent.ACTION_DOWN
                    val keyCode = call.argument<Int>("keyCode") ?: KeyEvent.KEYCODE_UNKNOWN
                    val port = call.argument<Int>("port") ?: 0
                    controller.sendKeyEvent(action, keyCode, port)
                    result.success(true)
                }
                "getBuiltinCoresVersion" -> {
                    val ctx = activity?.applicationContext
                    if (ctx == null) {
                        result.success(BuiltinCoresStore.DEFAULT_CORES_VERSION)
                    } else {
                        result.success(BuiltinCoreUpdater.getCoresVersion(ctx))
                    }
                }
                "getBundledLibretroDroidVersion" -> {
                    val ctx = activity?.applicationContext
                    if (ctx == null) {
                        result.success(BuiltinCoreUpdater.BUNDLED_LIBRETRODROID_VERSION)
                    } else {
                        result.success(BuiltinCoreUpdater.getActiveLibretroDroidVersion(ctx))
                    }
                }
                "downloadLibretroDroidEngine" -> {
                    val ctx = activity?.applicationContext
                    if (ctx == null) {
                        result.error("no_context", "Activity not attached", null)
                        return
                    }
                    val version = call.argument<String>("version")
                    if (version.isNullOrBlank()) {
                        result.error("invalid_args", "version is required", null)
                        return
                    }
                    result.success(BuiltinCoreUpdater.downloadLibretroDroidEngine(ctx, version))
                }
                "downloadAllBuiltinCores" -> {
                    val ctx = activity?.applicationContext
                    if (ctx == null) {
                        result.error("no_context", "Activity not attached", null)
                        return
                    }
                    val version = call.argument<String>("version")
                    if (version.isNullOrBlank()) {
                        result.error("invalid_args", "version is required", null)
                        return
                    }
                    val count = BuiltinCoreUpdater.downloadAllCores(ctx, version)
                    result.success(count)
                }
                "setBuiltinCoresVersion" -> {
                    val ctx = activity?.applicationContext
                    if (ctx == null) {
                        result.error("no_context", "Activity not attached", null)
                        return
                    }
                    val version = call.argument<String>("version")
                    if (version.isNullOrBlank()) {
                        result.error("invalid_args", "version is required", null)
                        return
                    }
                    BuiltinCoreUpdater.setCoresVersion(ctx, version)
                    result.success(true)
                }
                "hasPhysicalGamepad" -> {
                    result.success(hasPhysicalGamepad(activity))
                }
                "ensureCoreReady" -> {
                    val ctx = activity?.applicationContext
                    if (ctx == null) {
                        result.error("no_context", "Activity not attached", null)
                        return
                    }
                    val systemId = call.argument<String>("systemId")
                    if (systemId.isNullOrBlank()) {
                        result.error("invalid_args", "systemId is required", null)
                        return
                    }
                    val romPath = call.argument<String>("romPath")
                    val mapping =
                        CoreMappingRegistry.forSystem(systemId)
                            ?: run {
                                result.error(
                                    "unsupported",
                                    "No embedded core for system: $systemId",
                                    null,
                                )
                                return
                            }
                    Thread(
                        {
                            try {
                                if (!romPath.isNullOrBlank()) {
                                    controller.prepareLaunch(ctx, systemId, romPath)
                                } else {
                                    CoreResolver.resolve(ctx, mapping)
                                    if (mapping.coreName == "ppsspp") {
                                        PpssppAssetsManager.ensureAssets(ctx)
                                    }
                                }
                                android.os.Handler(android.os.Looper.getMainLooper()).post {
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                android.os.Handler(android.os.Looper.getMainLooper()).post {
                                    result.error(
                                        "core_unavailable",
                                        e.message ?: "Core download failed",
                                        null,
                                    )
                                }
                            }
                        },
                        "omisu-ensure-core",
                    ).start()
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            eventSink?.error("embedded_error", e.message, null)
            result.error("embedded_error", e.message, null)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        keyListener = { event -> controller.handleKeyEvent(event) }
        motionListener = { event -> controller.handleMotionEvent(event) }
        if (binding.activity is KeyEventForwardingActivity) {
            val host = binding.activity as KeyEventForwardingActivity
            host.embeddedKeyListener = keyListener
            host.embeddedMotionListener = motionListener
        }
        binding.addRequestPermissionsResultListener { _, _, _ -> false }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachKeyListener()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachKeyListener()
        activity = null
    }

    private fun detachKeyListener() {
        if (activity is KeyEventForwardingActivity) {
            val host = activity as KeyEventForwardingActivity
            host.embeddedKeyListener = null
            host.embeddedMotionListener = null
        }
        keyListener = null
        motionListener = null
    }

    private fun hasPhysicalGamepad(activity: Activity?): Boolean {
        if (activity == null) return false
        val inputManager =
            activity.getSystemService(Context.INPUT_SERVICE) as InputManager
        return inputManager.inputDeviceIds.any { deviceId ->
            val device = InputDevice.getDevice(deviceId) ?: return@any false
            (device.sources and InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD ||
                (device.sources and InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK
        }
    }

    companion object {
        const val CHANNEL = "com.omisu.launcher/embedded_emulator"
        const val EVENT_CHANNEL = "com.omisu.launcher/embedded_emulator_events"
        const val VIEW_TYPE = "embedded-retro-view"
    }
}

interface KeyEventForwardingActivity {
    var embeddedKeyListener: ((KeyEvent) -> Boolean)?
    var embeddedMotionListener: ((MotionEvent) -> Boolean)?
}
