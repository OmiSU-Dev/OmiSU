package com.omisu.embedded

import android.content.Context

object BuiltinCoresStore {
    private const val PREFS_NAME = "omisu_builtin_player"
    private const val KEY_CORES_VERSION = "cores_version"
    const val DEFAULT_CORES_VERSION = "1.17.0"

    fun getActiveVersion(context: Context): String {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_CORES_VERSION, DEFAULT_CORES_VERSION) ?: DEFAULT_CORES_VERSION
    }

    fun setActiveVersion(context: Context, version: String) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_CORES_VERSION, version).apply()
    }
}
