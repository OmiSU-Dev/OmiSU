package com.omisu.streaming

import android.util.Log

/**
 * Single log tag for external-play / RTMP manual tests over wireless adb.
 * Filter: `adb logcat -s OmisuStreamTrace` or `./scripts/logcat-external-play-stream.sh`
 */
object OmisuStreamTrace {
    const val TAG = "OmisuStreamTrace"

    fun event(phase: String, detail: String = "") {
        if (detail.isEmpty()) {
            Log.i(TAG, phase)
        } else {
            Log.i(TAG, "$phase | $detail")
        }
    }

    fun warn(phase: String, detail: String) {
        Log.w(TAG, "$phase | $detail")
    }

    fun error(phase: String, detail: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.e(TAG, "$phase | $detail", throwable)
        } else {
            Log.e(TAG, "$phase | $detail")
        }
    }
}
