package com.omisu.embedded

import android.app.ActivityManager
import android.content.Context

object EmbeddedGlUtils {
    /** GLES major version (2 or 3). CUT2/CUT3 HD shaders require GLES 3. */
    fun getGLSLVersion(context: Context): Int {
        val activityManager =
            context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return if (activityManager.deviceConfigurationInfo.reqGlEsVersion >= 0x30000) {
            3
        } else {
            2
        }
    }
}
