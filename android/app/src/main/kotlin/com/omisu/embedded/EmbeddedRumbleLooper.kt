package com.omisu.embedded

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.swordfish.libretrodroid.GLRetroView
import com.swordfish.libretrodroid.RumbleEvent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

class EmbeddedRumbleLooper(
    private val context: Context,
) {
    private val scope = CoroutineScope(Dispatchers.Default)
    private var job: Job? = null

    fun start(view: GLRetroView) {
        stop()
        job =
            scope.launch {
                view
                    .getRumbleEvents()
                    .catch { /* ignore stream errors on teardown */ }
                    .collect { event -> vibrate(event) }
            }
    }

    fun stop() {
        job?.cancel()
        job = null
    }

    private fun vibrate(event: RumbleEvent) {
        val vibrator = vibrator() ?: return
        val strength = event.strengthStrong * 0.66f + event.strengthWeak * 0.33f
        val amplitude = (0.5f * strength * 255).roundToInt().coerceIn(1, 255)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(120, amplitude))
        } else {
            vibrator.vibrate(120)
        }
    }

    private fun vibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
