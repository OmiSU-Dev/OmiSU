package com.omisu.embedded

import android.content.Context

/** Remembers the highest HD tier that ran smoothly per system on this device. */
object EmbeddedAdaptiveHdStore {
    /** Bumped when start-quality logic changes so stale tiers are not reused. */
    private const val PREFS = "omisu_adaptive_hd_v2"

    fun get(context: Context, systemFolder: String): EmbeddedHdModeQuality? {
        val key = prefKey(systemFolder)
        val stored =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(key, null)
                ?: return null
        return EmbeddedHdModeQuality.parse(stored)
    }

    fun set(context: Context, systemFolder: String, quality: EmbeddedHdModeQuality) {
        val key = prefKey(systemFolder)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(key, quality.name.lowercase())
            .apply()
    }

    /**
     * Start at the lower of user ceiling and remembered stable tier.
     *
     * With no history, start at [EmbeddedHdModeQuality.LOW] so CUT2/CUT3 is not
     * applied on the first frames. Some Adreno GPUs still hit target FPS while
     * a broken medium HD shader leaves a black picture.
     */
    fun resolveStartQuality(
        context: Context,
        systemFolder: String,
        userCeiling: EmbeddedHdModeQuality,
    ): EmbeddedHdModeQuality {
        val remembered = get(context, systemFolder) ?: return EmbeddedHdModeQuality.LOW
        return minOf(remembered, userCeiling)
    }

    private fun prefKey(systemFolder: String): String =
        "system_${EmbeddedSystemTuningRegistry.canonicalSystemId(systemFolder)}"
}
