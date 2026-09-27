package com.omisu.streaming

import android.app.ActivityManager
import android.content.Context
import android.util.Size

object StreamQualityResolver {
    fun effectivePreset(context: Context, stored: String): String {
        if (stored != "auto") {
            return when (stored) {
                "1080p", "540p", "720p" -> stored
                else -> "720p"
            }
        }
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mem = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mem)
        val totalRamGb = (mem.totalMem / (1024L * 1024L * 1024L)).toInt().coerceAtLeast(1)
        return if (totalRamGb >= 8) "720p" else "540p"
    }

    fun fpsFor(context: Context, stored: String): Int {
        if (stored == "auto") return 30
        return if (effectivePreset(context, stored) == "1080p") 30 else 24
    }

    /**
     * Auto quality uses fixed mobile RTMP targets (no pixel scaling). Ultrawide
     * external encode keeps the same bitrate cap so Kick uplink stays stable.
     * StreamPack still adjusts slightly inside [StreamingController]'s regulator band.
     */
    fun autoVideoBitrateKbps(
        context: Context,
        @Suppress("UNUSED_PARAMETER") encodeSize: Size,
        externalPlay: Boolean,
    ): Int {
        return fixedBitrateKbpsForPreset(effectivePreset(context, "auto"), externalPlay)
    }

    fun fixedBitrateKbpsForPreset(preset: String, externalPlay: Boolean): Int {
        val kbps =
            when (preset) {
                "1080p" -> 3500
                "720p" -> 1800
                else -> 1200
            }
        return if (externalPlay) {
            when (preset) {
                "1080p" -> 2200
                "720p" -> 1500
                else -> 1500
            }
        } else {
            kbps
        }
    }

    fun encodeTriple(context: Context, stored: String): Triple<Int, Int, Int> {
        val preset = effectivePreset(context, stored)
        val (w, h) =
            when (preset) {
                "1080p" -> 1920 to 1080
                "720p" -> 1280 to 720
                else -> 960 to 540
            }
        val br =
            if (stored == "auto") {
                autoVideoBitrateKbps(context, Size(w, h), externalPlay = false)
            } else {
                when (preset) {
                    "1080p" -> 3500
                    "720p" -> 1800
                    else -> 1200
                }
            }
        return Triple(w, h, br)
    }
}
