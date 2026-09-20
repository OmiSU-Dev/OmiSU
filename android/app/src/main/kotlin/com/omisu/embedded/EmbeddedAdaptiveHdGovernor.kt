package com.omisu.embedded

/**
 * Steps HD upscaler quality down when FPS sags and back up when stable.
 *
 * Hysteresis avoids flapping; warmup ignores the first samples after core load.
 */
class EmbeddedAdaptiveHdGovernor(
    private val userCeiling: EmbeddedHdModeQuality,
    startQuality: EmbeddedHdModeQuality,
    private val onQualityChanged: (EmbeddedHdModeQuality) -> Unit,
) {
    var effectiveQuality: EmbeddedHdModeQuality = startQuality
        private set

    private var warmupWindowsRemaining = WARMUP_WINDOWS
    private var lowFpsStreak = 0
    private var highFpsStreak = 0

    fun onFpsWindow(fps: Double) {
        if (warmupWindowsRemaining > 0) {
            warmupWindowsRemaining--
            return
        }

        if (fps < LOW_FPS_THRESHOLD) {
            lowFpsStreak++
            highFpsStreak = 0
            if (lowFpsStreak >= LOW_FPS_WINDOWS && effectiveQuality > EmbeddedHdModeQuality.LOW) {
                stepDown()
            }
            return
        }

        lowFpsStreak = 0

        if (fps >= HIGH_FPS_THRESHOLD && effectiveQuality < userCeiling) {
            highFpsStreak++
            if (highFpsStreak >= HIGH_FPS_WINDOWS) {
                stepUp()
            }
        } else {
            highFpsStreak = 0
        }
    }

    fun reset(userCeiling: EmbeddedHdModeQuality, startQuality: EmbeddedHdModeQuality) {
        warmupWindowsRemaining = WARMUP_WINDOWS
        lowFpsStreak = 0
        highFpsStreak = 0
        if (startQuality != effectiveQuality) {
            effectiveQuality = startQuality
            onQualityChanged(startQuality)
        }
    }

    private fun stepDown() {
        lowFpsStreak = 0
        highFpsStreak = 0
        val next =
            when (effectiveQuality) {
                EmbeddedHdModeQuality.HIGH -> EmbeddedHdModeQuality.MEDIUM
                EmbeddedHdModeQuality.MEDIUM -> EmbeddedHdModeQuality.LOW
                EmbeddedHdModeQuality.LOW -> return
            }
        effectiveQuality = next
        onQualityChanged(next)
    }

    private fun stepUp() {
        highFpsStreak = 0
        lowFpsStreak = 0
        val next =
            when (effectiveQuality) {
                EmbeddedHdModeQuality.LOW -> EmbeddedHdModeQuality.MEDIUM
                EmbeddedHdModeQuality.MEDIUM -> EmbeddedHdModeQuality.HIGH
                EmbeddedHdModeQuality.HIGH -> return
            }
        if (next > userCeiling) return
        effectiveQuality = next
        onQualityChanged(next)
    }

    companion object {
        const val WINDOW_MS = 2_000.0
        private const val LOW_FPS_THRESHOLD = 52.0
        private const val HIGH_FPS_THRESHOLD = 58.0
        private const val LOW_FPS_WINDOWS = 2
        private const val HIGH_FPS_WINDOWS = 5
        private const val WARMUP_WINDOWS = 3
    }
}
