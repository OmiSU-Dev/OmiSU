package com.omisu.embedded

import android.content.Context

/** Remembers the highest HD tier that ran smoothly per system on this device. */
object EmbeddedAdaptiveHdStore {
    private const val PREFS = "omisu_adaptive_hd"

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

    /** Start at the lower of user ceiling and remembered stable tier. */
    fun resolveStartQuality(
        context: Context,
        systemFolder: String,
        userCeiling: EmbeddedHdModeQuality,
    ): EmbeddedHdModeQuality {
        val remembered = get(context, systemFolder) ?: return userCeiling
        return minOf(remembered, userCeiling)
    }

    private fun prefKey(systemFolder: String): String =
        "system_${EmbeddedSystemTuningRegistry.canonicalSystemId(systemFolder)}"
}
