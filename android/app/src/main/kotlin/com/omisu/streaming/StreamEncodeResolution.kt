package com.omisu.streaming

import android.content.Context
import android.util.Log
import android.util.Size
import io.github.thibaultbee.streampack.core.elements.utils.extensions.screenRect
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * External Play Store games use the full device display. Fixed 16:9 encode sizes
 * cause StreamPack to center-crop ultrawide panels; match display aspect instead.
 */
internal object StreamEncodeResolution {
    private const val TAG = "StreamEncodeResolution"

    /** ~720p pixel budget for mobile RTMP (same cap as [StreamingController] external path). */
    private const val EXTERNAL_MAX_PIXELS = 1280L * 720L

    fun forExternalPlay(
        context: Context,
        presetWidth: Int,
        presetHeight: Int,
    ): Size {
        val displayW: Int
        val displayH: Int
        if (ExternalPlayStreamCapture.displayLongEdgePx >= 2 &&
            ExternalPlayStreamCapture.displayShortEdgePx >= 2
        ) {
            displayW = ExternalPlayStreamCapture.displayLongEdgePx
            displayH = ExternalPlayStreamCapture.displayShortEdgePx
        } else {
            val bounds = context.screenRect
            displayW = max(bounds.width(), bounds.height())
            displayH = min(bounds.width(), bounds.height())
        }
        if (displayW < 2 || displayH < 2) {
            return alignEven(presetWidth, presetHeight)
        }

        var h = presetHeight.coerceIn(480, 1080)
        var w = ((h.toLong() * displayW + displayH / 2) / displayH).toInt()

        val pixels = w.toLong() * h
        if (pixels > EXTERNAL_MAX_PIXELS) {
            val scale = sqrt(EXTERNAL_MAX_PIXELS.toDouble() / pixels.toDouble())
            w = (w * scale).toInt()
            h = (h * scale).toInt()
        }

        w = even(w.coerceIn(854, 1920))
        h = even(h.coerceIn(480, 1080))

        // Re-sync width to aspect after even/coerce (avoid drifting back to 16:9).
        val aspectW = ((h.toLong() * displayW + displayH / 2) / displayH).toInt()
        if (aspectW in 854..1920) {
            w = even(aspectW)
        }

        Log.i(
            TAG,
            "External play encode ${w}x$h (display ${displayW}x${displayH}, preset ${presetWidth}x$presetHeight)",
        )
        return Size(w, h)
    }

    private fun even(v: Int): Int = v and 0x7FFFFFFE

    private fun alignEven(width: Int, height: Int): Size {
        var w = even(width.coerceIn(854, 1920))
        var h = even(height.coerceIn(480, 1080))
        return Size(w, h)
    }
}
