package com.omisu.launcher

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import android.view.KeyEvent

/**
 * After the display turns off, waits [idleMinutes] then attempts USB suspend and enters
 * [hostSleepActive] until the user presses a controller wake key (HOME / PS / Start).
 */
class ControllerIdleSleepManager(
    private val context: Context,
    private val onHostSleepChanged: (active: Boolean, usbCut: Boolean) -> Unit,
    private val wakeDisplay: () -> Unit,
) {
    companion object {
        private const val TAG = "ControllerIdleSleep"
        private const val PREFS = "nordi_controller_power"
        private const val KEY_MINUTES = "idle_minutes"
        private const val KEY_SUSPEND_ON_NORDI_SLEEP = "suspend_on_nordi_sleep"
        const val DEFAULT_IDLE_MINUTES = 5
    }

    private val handler = Handler(Looper.getMainLooper())
    private var cutRunnable: Runnable? = null
    private var hostSleepActive = false
    private var lastUsbCut = false

    private fun prefs() =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    var idleMinutes: Int
        get() = prefs().getInt(KEY_MINUTES, DEFAULT_IDLE_MINUTES)
        set(value) {
            prefs().edit()
                .putInt(KEY_MINUTES, value.coerceIn(0, 120))
                .apply()
            if (value <= 0) cancelScheduledCut()
        }

    /** When true, [enterHostSleepImmediately] runs as soon as Nordi Sleep turns the display off. */
    var suspendOnNordiSleepEnter: Boolean
        get() = prefs().getBoolean(KEY_SUSPEND_ON_NORDI_SLEEP, false)
        set(value) {
            prefs().edit().putBoolean(KEY_SUSPEND_ON_NORDI_SLEEP, value).apply()
        }

    fun isHostSleepActive(): Boolean = hostSleepActive

    fun onDisplayOff() {
        cancelScheduledCut()
        val minutes = idleMinutes
        if (minutes <= 0) return
        val delayMs = minutes * 60_000L
        Log.i(TAG, "Display off — scheduling controller cut in ${minutes}m")
        cutRunnable = Runnable { enterHostSleep() }
        handler.postDelayed(cutRunnable!!, delayMs)
    }

    fun onDisplayOn() {
        // Cancel a pending cut if the display wakes before the idle timer fires.
        // Do not exit [hostSleepActive] here — the user must press a controller wake key.
        cancelScheduledCut()
    }

    fun cancelScheduledCut() {
        cutRunnable?.let { handler.removeCallbacks(it) }
        cutRunnable = null
    }

    fun enterHostSleepImmediately(): HostSleepResult {
        cancelScheduledCut()
        return enterHostSleep()
    }

    private fun enterHostSleep(): HostSleepResult {
        if (hostSleepActive) {
            return HostSleepResult(true, lastUsbCut)
        }
        lastUsbCut = ControllerHostPowerHelper.suspendGamepad()
        hostSleepActive = true
        Log.i(TAG, "Controller host sleep active usbCut=$lastUsbCut")
        onHostSleepChanged(true, lastUsbCut)
        return HostSleepResult(true, lastUsbCut)
    }

    fun exitHostSleep(wakeDisplayToo: Boolean): HostSleepResult {
        if (!hostSleepActive) {
            return HostSleepResult(false, false)
        }
        val resumed = ControllerHostPowerHelper.resumeGamepad()
        hostSleepActive = false
        Log.i(TAG, "Controller host sleep exit usbResume=$resumed")
        onHostSleepChanged(false, false)
        if (wakeDisplayToo) {
            wakeDisplay()
        }
        return HostSleepResult(true, resumed)
    }

    fun isControllerWakeKey(keyCode: Int): Boolean =
        keyCode == KeyEvent.KEYCODE_BUTTON_START ||
            keyCode == KeyEvent.KEYCODE_MENU ||
            keyCode == KeyEvent.KEYCODE_BUTTON_MODE ||
            keyCode == KeyEvent.KEYCODE_GUIDE ||
            keyCode == KeyEvent.KEYCODE_HOME

    data class HostSleepResult(val active: Boolean, val usbOpOk: Boolean)
}
