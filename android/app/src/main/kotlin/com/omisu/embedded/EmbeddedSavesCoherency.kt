package com.omisu.embedded

import android.content.Context

/**
 * Prevents loading a stale autosave when in-game SRAM is newer (Lemuroid pattern).
 *
 * Scenario: autosave on → play → autosave off → long session with battery save →
 * autosave on again → old autosave would wipe progress without this guard.
 */
object EmbeddedSavesCoherency {
    private const val TOLERANCE_MS = 30_000L

    fun shouldDiscardAutosave(
        context: Context,
        coreName: String,
        romBase: String,
    ): Boolean {
        val sram =
            EmbeddedSavesManager.newestSramFile(context, coreName, romBase) ?: return false
        val autosave = EmbeddedSavesManager.autosaveFile(context, coreName, romBase)
        if (!autosave.exists() || autosave.length() == 0L) return false
        return sram.lastModified() > autosave.lastModified() + TOLERANCE_MS
    }
}
