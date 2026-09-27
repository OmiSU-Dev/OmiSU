package com.omisu.streaming

import android.app.Activity
import kotlin.math.max
import kotlin.math.min

/**
 * True while an external Android game session should use [MediaProjection] video
 * (not [EmbeddedRetroVideoSource]).
 */
object ExternalPlayStreamCapture {
    @Volatile
    var isActive: Boolean = false
        internal set

    /** Physical display long/short edge from the capture consent activity (not service context). */
    @Volatile
    var displayLongEdgePx: Int = 0
        private set

    @Volatile
    var displayShortEdgePx: Int = 0
        private set

    fun recordDisplayFrom(activity: Activity) {
        val bounds = activity.windowManager.currentWindowMetrics.bounds
        displayLongEdgePx = max(bounds.width(), bounds.height())
        displayShortEdgePx = min(bounds.width(), bounds.height())
        OmisuStreamTrace.event(
            "capture_display_metrics",
            "long=$displayLongEdgePx short=$displayShortEdgePx",
        )
    }

    fun clearDisplayMetrics() {
        displayLongEdgePx = 0
        displayShortEdgePx = 0
    }
}
