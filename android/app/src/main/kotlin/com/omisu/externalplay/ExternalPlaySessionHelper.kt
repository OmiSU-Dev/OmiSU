package com.omisu.externalplay

import android.content.Context
import android.content.pm.ActivityInfo
import android.view.Surface
import com.omisu.streaming.EmbeddedStreamCapture
import com.omisu.streaming.ExternalPlayStreamCapture
import com.omisu.streaming.OmisuStreamTrace

/**
 * Tracks an Android app / Play Store game launched from OmiSU (not embedded libretro).
 * Stream options are chosen in Flutter before launch; controller Start is not remapped.
 */
object ExternalPlaySessionHelper {
    @Volatile
    var isActive: Boolean = false
        private set

    @Volatile
    var gameTitle: String = ""
        private set

    @Volatile
    var gamePackageName: String = ""
        private set

    @Volatile
    var isMenuVisible: Boolean = false
        internal set

    private var appContext: Context? = null

    /** Call before RTMP + MediaProjection while OmiSU is still foreground. */
    fun prepareStreamingCapture(packageName: String = "") {
        EmbeddedStreamCapture.unregister(null)
        ExternalPlayStreamCapture.isActive = true
        if (packageName.isNotBlank()) {
            gamePackageName = packageName
        }
        OmisuStreamTrace.event(
            "external_prepare",
            "package=$gamePackageName active=$isActive",
        )
    }

    fun begin(context: Context, title: String, packageName: String) {
        appContext = context.applicationContext
        prepareStreamingCapture(packageName)
        isActive = true
        gameTitle = title.ifBlank { "Game" }
        gamePackageName = packageName
        captureDisplayLandscapeOrientation(context)
        ExternalPlaySessionService.start(appContext!!, gameTitle)
        OmisuStreamTrace.event(
            "external_session_begin",
            "title=$gameTitle package=$packageName",
        )
    }

    private fun captureDisplayLandscapeOrientation(context: Context) {
        val rotation =
            context.display?.rotation
                ?: (context.getSystemService(Context.WINDOW_SERVICE) as? android.view.WindowManager)
                    ?.defaultDisplay
                    ?.rotation
                ?: return
        menuLandscapeOrientation =
            when (rotation) {
                Surface.ROTATION_90 -> ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
                Surface.ROTATION_270 -> ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE
                else -> ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
            }
    }

    @Volatile
    var menuLandscapeOrientation: Int = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        private set

    fun end() {
        ExternalPlayStreamCaptureActivity.cancelPendingLaunch()
        appContext?.let { ExternalPlaySessionService.stop(it) }
        appContext = null
        isActive = false
        gameTitle = ""
        gamePackageName = ""
        isMenuVisible = false
        ExternalPlayStreamCapture.isActive = false
        ExternalPlayStreamCapture.clearDisplayMetrics()
        OmisuStreamTrace.event("external_session_end")
    }
}
