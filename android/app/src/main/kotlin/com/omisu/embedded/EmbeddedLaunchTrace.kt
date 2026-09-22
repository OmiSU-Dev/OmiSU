package com.omisu.embedded

import android.util.Log

/**
 * Filter logcat with: adb logcat | rg OmiSULaunch
 *
 * Single-line launch timeline for embedded play (video/audio/surface issues).
 */
object EmbeddedLaunchTrace {
    private const val TAG = "OmiSULaunch"

    fun event(phase: String, detail: String = "") {
        if (detail.isEmpty()) {
            Log.i(TAG, phase)
        } else {
            Log.i(TAG, "$phase | $detail")
        }
    }
}
