package com.omisu.streaming

/**
 * Maps a quality target into live RTMP bitrates: start low for stability, allow a wide
 * downward range on packet loss, ramp toward the cap when the uplink is healthy.
 */
object StreamUplinkAdaptation {
    data class VideoBitratePlan(
        val startBps: Int,
        val minBps: Int,
        val maxBps: Int,
    )

    fun plan(targetMaxBps: Int, externalPlay: Boolean): VideoBitratePlan {
        val maxBps = targetMaxBps.coerceAtLeast(600_000)
        val minBps =
            if (externalPlay) {
                maxOf(450_000, (maxBps * 0.28f).toInt())
            } else {
                maxOf(500_000, (maxBps * 0.30f).toInt())
            }
        val startFactor = if (externalPlay) 0.55f else 0.50f
        val startBps = (maxBps * startFactor).toInt().coerceIn(minBps, maxBps)
        return VideoBitratePlan(startBps, minBps, maxBps)
    }
}
