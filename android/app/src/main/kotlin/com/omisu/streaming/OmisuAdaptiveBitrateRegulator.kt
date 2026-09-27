package com.omisu.streaming

import io.github.thibaultbee.streampack.core.configuration.BitrateRegulatorConfig
import io.github.thibaultbee.streampack.core.elements.metrics.EndpointMetricsTracker
import io.github.thibaultbee.streampack.core.elements.metrics.writtenBitrateInBps
import io.github.thibaultbee.streampack.core.regulator.BitrateRegulator
import io.github.thibaultbee.streampack.core.regulator.IBitrateRegulator
import kotlin.math.max
import kotlin.math.min

/**
 * RTMP uplink regulator: reacts to [EndpointMetricsTracker] packet loss/drops (connection
 * health) and ramps bitrate up only after several stable polls.
 */
class OmisuAdaptiveBitrateRegulator(
    metricsTracker: EndpointMetricsTracker,
    bitrateRegulatorConfig: BitrateRegulatorConfig,
    onVideoTargetBitrateChange: (Int) -> Unit,
    onAudioTargetBitrateChange: (Int) -> Unit,
) : BitrateRegulator(
        metricsTracker,
        bitrateRegulatorConfig,
        onVideoTargetBitrateChange,
        onAudioTargetBitrateChange,
    ) {
    private var consecutiveStablePolls = 0
    private var lastLoggedVideoBps = -1

    override fun update(currentVideoBitrate: Int, currentAudioBitrate: Int) {
        val metrics = metricsTracker.instant
        val packetsLostOrDropped = metrics.packetsWriteDropped + metrics.packetsWriteLost
        val writtenBitrate = metrics.writtenBitrateInBps

        if (packetsLostOrDropped > 0) {
            consecutiveStablePolls = 0
            val percentageReduction =
                if (metrics.packetsWritten == 0L) {
                    MAX_PERCENTAGE_DECREASE
                } else {
                    (packetsLostOrDropped * 100 / metrics.packetsWritten)
                        .toInt()
                        .coerceIn(MIN_PERCENTAGE_DECREASE, MAX_PERCENTAGE_DECREASE)
                }
            val newVideoBitrate =
                currentVideoBitrate -
                    max(
                        currentVideoBitrate * percentageReduction / 100,
                        MIN_DECREASE_STEP,
                    )
            OmisuStreamTrace.warn(
                "uplink_congestion",
                "drops=$packetsLostOrDropped written=${writtenBitrate / 1000}kbps " +
                    "target=${currentVideoBitrate / 1000}→${newVideoBitrate / 1000}kbps",
            )
            onVideoTargetBitrateChange(newVideoBitrate)
            logTargetIfChanged(newVideoBitrate)
        } else if (currentVideoBitrate < bitrateRegulatorConfig.videoBitrateRange.upper) {
            if (writtenBitrate > currentVideoBitrate * STABLE_WRITTEN_FRACTION) {
                consecutiveStablePolls++
            } else {
                consecutiveStablePolls = 0
            }
            if (consecutiveStablePolls >= STABLE_POLLS_BEFORE_INCREASE) {
                consecutiveStablePolls = 0
                val newVideoBitrate =
                    min(
                        currentVideoBitrate + MAX_INCREASE_STEP,
                        bitrateRegulatorConfig.videoBitrateRange.upper,
                    )
                OmisuStreamTrace.event(
                    "uplink_stable",
                    "raising video ${currentVideoBitrate / 1000}→${newVideoBitrate / 1000}kbps",
                )
                onVideoTargetBitrateChange(newVideoBitrate)
                logTargetIfChanged(newVideoBitrate)
            }
        }
    }

    private fun logTargetIfChanged(videoBps: Int) {
        val clamped =
            videoBps.coerceIn(
                bitrateRegulatorConfig.videoBitrateRange.lower,
                bitrateRegulatorConfig.videoBitrateRange.upper,
            )
        if (clamped != lastLoggedVideoBps) {
            lastLoggedVideoBps = clamped
            OmisuStreamTrace.event(
                "uplink_video_bitrate",
                "${clamped / 1000}kbps " +
                    "(range ${bitrateRegulatorConfig.videoBitrateRange.lower / 1000}–" +
                    "${bitrateRegulatorConfig.videoBitrateRange.upper / 1000})",
            )
        }
    }

    class Factory : IBitrateRegulator.Factory {
        override fun newBitrateRegulator(
            metricsTracker: EndpointMetricsTracker,
            bitrateRegulatorConfig: BitrateRegulatorConfig,
            onVideoTargetBitrateChange: (Int) -> Unit,
            onAudioTargetBitrateChange: (Int) -> Unit,
        ): OmisuAdaptiveBitrateRegulator =
            OmisuAdaptiveBitrateRegulator(
                metricsTracker,
                bitrateRegulatorConfig,
                onVideoTargetBitrateChange,
                onAudioTargetBitrateChange,
            )
    }

    companion object {
        private const val MIN_DECREASE_STEP = 120_000
        private const val MAX_INCREASE_STEP = 150_000
        private const val MAX_PERCENTAGE_DECREASE = 90
        private const val MIN_PERCENTAGE_DECREASE = 25
        private const val STABLE_WRITTEN_FRACTION = 0.88
        private const val STABLE_POLLS_BEFORE_INCREASE = 4
    }
}
