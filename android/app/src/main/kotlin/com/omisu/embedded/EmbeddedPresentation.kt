package com.omisu.embedded

import android.app.Activity
import android.graphics.PixelFormat
import android.os.Build
import android.view.View
import com.swordfish.libretrodroid.GLRetroView
import java.util.Locale

/**
 * Hybrid-composition hints for [GLRetroView] on OEM devices where the GL
 * surface can stay black while the core runs (audio + first_frame in logs).
 */
object EmbeddedPresentation {
    fun configureSurface(activity: Activity, view: GLRetroView) {
        view.holder.setFormat(PixelFormat.OPAQUE)
        // On test / legacy devices (e.g. ZTE Bolton), draw the SurfaceView as a
        // media overlay so Flutter hybrid composition can see pixels. Nord N30
        // keeps the default z-order so in-game UI stays predictable.
        view.setZOrderMediaOverlay(!isPrimaryHandheldTarget(activity))
    }

    fun syncHybridCompositor(activity: Activity, view: GLRetroView) {
        view.post {
            var parent: View? = view.parent as? View
            while (parent != null) {
                parent.invalidate()
                parent.requestLayout()
                parent = parent.parent as? View
            }
            activity.window?.decorView?.invalidate()
            view.requestRender()
            EmbeddedLaunchTrace.event(
                "presentation_sync",
                "model=${Build.MODEL} zMediaOverlay=${!isPrimaryHandheldTarget(activity)}",
            )
        }
    }

    private fun isPrimaryHandheldTarget(activity: Activity): Boolean {
        val model = Build.MODEL.lowercase(Locale.US)
        val device = Build.DEVICE.lowercase(Locale.US)
        return model.contains("nord n30") ||
            model.contains("cph258") ||
            device.contains("cph258")
    }
}
