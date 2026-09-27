package com.omisu.launcher

import android.util.Log
import java.io.File

/**
 * Best-effort USB host suspend/resume for a plugged-in gamepad (e.g. N01 DS4-clone).
 * Retail apps usually lack sysfs permission; [suspendGamepad] may return false and callers
 * should fall back to soft sleep (input block until wake key).
 */
object ControllerHostPowerHelper {
    private const val TAG = "ControllerHostPower"

    /** DS4-clones (N01), GameSir X5 Lite (3537:1116), common pad vendors. */
    private val GAMEPAD_VENDORS = setOf("054c", "0079", "045e", "20d6", "3537")

    fun findGamepadUsbDeviceDir(): File? {
        val root = File("/sys/bus/usb/devices")
        val entries = root.listFiles() ?: return null
        for (entry in entries) {
            if (!entry.name.matches(Regex("""\d+-\d+"""))) continue
            val vendor = readTrim(entry, "idVendor") ?: continue
            if (!GAMEPAD_VENDORS.contains(vendor.lowercase())) continue
            val powerControl = File(entry, "power/control")
            if (powerControl.exists()) {
                Log.i(TAG, "Gamepad USB node: ${entry.absolutePath} vendor=$vendor")
                return entry
            }
        }
        return null
    }

    fun suspendGamepad(): Boolean {
        val dir = findGamepadUsbDeviceDir() ?: return false
        return writePowerControl(dir, "suspend") || suWritePowerControl(dir, "suspend")
    }

    fun resumeGamepad(): Boolean {
        val dir = findGamepadUsbDeviceDir() ?: return false
        return writePowerControl(dir, "on") || suWritePowerControl(dir, "on")
    }

    private fun readTrim(dir: File, name: String): String? {
        return try {
            File(dir, name).readText().trim()
        } catch (_: Exception) {
            null
        }
    }

    private fun writePowerControl(deviceDir: File, mode: String): Boolean {
        return try {
            File(deviceDir, "power/control").writeText(mode)
            Log.i(TAG, "power/control -> $mode (app uid)")
            true
        } catch (e: Exception) {
            Log.w(TAG, "power/control $mode failed: ${e.message}")
            false
        }
    }

    private fun suWritePowerControl(deviceDir: File, mode: String): Boolean {
        val path = File(deviceDir, "power/control").absolutePath
        val cmd = "echo $mode > $path"
        return try {
            val proc = Runtime.getRuntime().exec(arrayOf("su", "0", "sh", "-c", cmd))
            val ok = proc.waitFor() == 0
            if (ok) Log.i(TAG, "power/control -> $mode (su)")
            ok
        } catch (e: Exception) {
            Log.w(TAG, "su power/control failed: ${e.message}")
            false
        }
    }
}
