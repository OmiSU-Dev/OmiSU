package com.omisu.embedded

import android.app.Activity
import android.util.Log
import android.view.View
import androidx.lifecycle.LifecycleOwner
import com.swordfish.libretrodroid.GLRetroView
import io.flutter.plugin.platform.PlatformView

class EmbeddedRetroPlatformView(
    private val activity: Activity,
    private val controller: EmbeddedEmulatorController,
    creationParams: Map<String, Any>?,
) : PlatformView {
    private val retroView: GLRetroView

    init {
        val systemId = creationParams?.get("systemId") as? String
            ?: throw IllegalArgumentException("systemId is required")
        val romPath = creationParams["romPath"] as? String
            ?: throw IllegalArgumentException("romPath is required")
        val tuning = EmbeddedEmulatorController.parseTuning(creationParams)

        val lifecycleOwner =
            activity as? LifecycleOwner
                ?: throw IllegalStateException(
                    "Embedded play requires an Activity that implements LifecycleOwner",
                )

        retroView =
            controller.createRetroView(activity, systemId, romPath, tuning).also { view ->
                // Invoke onCreate directly instead of addObserver(). We tear down via
                // LibretroDroid.destroy() on the GL thread; addObserver would also call
                // destroy on the main thread during removeObserver and break PPSSPP.
                view.onCreate(lifecycleOwner)
                EmbeddedCoreGate.markSessionActive()
                Log.i(
                    TAG,
                    "Started GLRetroView session (lifecycle=${lifecycleOwner.lifecycle.currentState})",
                )
            }
    }

    override fun getView(): View =
        retroView.also { view ->
            // Do not call GLSurfaceView.onResume() here — GLRetroView registers its own
            // RenderLifecycleObserver after the game loads; an early resume races the
            // core and can SIGSEGV inside retro_run() on the first frame.
            view.post { view.requestFocus() }
        }

    override fun dispose() {
        val owner = activity as? LifecycleOwner
        if (owner != null && !controller.isViewDetached(retroView)) {
            controller.detachRetroView(owner, retroView, flushAutosave = false)
        } else {
            controller.dispose(flushAutosave = false)
        }
        Log.i(TAG, "PlatformView disposed")
    }

    companion object {
        private const val TAG = "EmbeddedRetroPlatformView"
    }
}
