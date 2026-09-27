package com.omisu.launcher

import android.app.Application
import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import com.omisu.embedded.LibretroDroidEngineUpdater

class OmiSUApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        runCatching { LibretroDroidEngineUpdater.pruneOldEngineVersions(this, "0.13.2") }

        if (shouldSkipCrashRelaunch()) {
            return
        }

        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            android.util.Log.e(
                "OmiSUApplication",
                "Uncaught exception on ${thread.name}",
                throwable,
            )
            try {
                val launch = packageManager.getLaunchIntentForPackage(packageName)
                if (launch != null) {
                    launch.addFlags(
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK,
                    )
                    startActivity(launch)
                }
            } catch (e: Exception) {
                android.util.Log.e("OmiSUApplication", "Crash relaunch failed: ${e.message}")
            }
            defaultHandler?.uncaughtException(thread, throwable)
                ?: Process.killProcess(Process.myPid())
        }
    }

    /**
     * Safe mode and non-HOME sideload runs skip auto-relaunch so a startup bug
     * does not loop (especially after switching to the stock launcher).
     */
    private fun shouldSkipCrashRelaunch(): Boolean {
        if (isNordiSafeMode()) return true
        return !holdsHomeRole()
    }

    private fun holdsHomeRole(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(RoleManager::class.java)
                if (roleManager.isRoleAvailable(RoleManager.ROLE_HOME)) {
                    return roleManager.isRoleHeld(RoleManager.ROLE_HOME)
                }
            }
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            val resolveInfo = packageManager.resolveActivity(
                intent,
                PackageManager.MATCH_DEFAULT_ONLY,
            )
            resolveInfo?.activityInfo?.packageName == packageName
        } catch (_: Exception) {
            false
        }
    }

    private fun isNordiSafeMode(): Boolean {
        val oem = getSharedPreferences("nordi_oem", MODE_PRIVATE)
        if (oem.getBoolean("safe_mode", false)) return true
        // Flutter may have persisted before native sync on a prior run.
        val flutter = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        return flutter.getString("flutter.nordi_safe_mode", "false") == "true"
    }
}
