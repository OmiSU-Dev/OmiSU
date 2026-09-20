package com.omisu.embedded

import android.content.Context

object LibretroDroidEngineStore {
    private const val PREFS_NAME = "omisu_builtin_player"
    private const val KEY_ENGINE_VERSION = "libretrodroid_version"

    fun getActiveVersion(context: Context): String {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_ENGINE_VERSION, BuiltinCoreUpdater.BUNDLED_LIBRETRODROID_VERSION)
            ?: BuiltinCoreUpdater.BUNDLED_LIBRETRODROID_VERSION
    }

    fun setActiveVersion(context: Context, version: String) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_ENGINE_VERSION, version).apply()
    }
}
