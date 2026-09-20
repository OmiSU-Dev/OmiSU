package com.omisu.embedded

import android.util.Log
import android.opengl.GLSurfaceView
import com.swordfish.libretrodroid.GLRetroView
import com.swordfish.libretrodroid.LibretroDroid
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Serializes LibretroDroid create/destroy so only one core is active at a time.
 *
 * PPSSPP and other heavy cores can SIGABRT if a new core loads before the
 * previous native teardown finishes.
 */
object EmbeddedCoreGate {
    private const val TAG = "EmbeddedCoreGate"
    private const val GL_DRAIN_TIMEOUT_SEC = 5L
    private const val HEAVY_COOLDOWN_MS = 1500L
    private const val DEFAULT_COOLDOWN_MS = 200L

    private val sessionLock = Any()

    @Volatile
    private var sessionActive = false

    private val heavyCores =
        setOf(
            "ppsspp",
            "mupen64plus_next_gles3",
            "citra",
            "melonds",
            "pcsx_rearmed",
        )

    /** Blocks until no core session is active and teardown has finished. */
    fun awaitCoreIdle(timeoutMs: Long = 15_000L) {
        val deadline = System.currentTimeMillis() + timeoutMs
        synchronized(sessionLock) {
            while (sessionActive && System.currentTimeMillis() < deadline) {
                try {
                    (sessionLock as Object).wait(50)
                } catch (_: InterruptedException) {
                    break
                }
            }
            if (sessionActive) {
                Log.w(TAG, "awaitCoreIdle timed out after ${timeoutMs}ms; forcing idle")
                sessionActive = false
            }
        }
    }

    fun markSessionActive() {
        synchronized(sessionLock) {
            sessionActive = true
            Log.i(TAG, "Core session active")
        }
    }

    fun resetSession() {
        synchronized(sessionLock) {
            sessionActive = false
            (sessionLock as Object).notifyAll()
        }
    }

    /**
     * Stops GL rendering, pauses emulation on the GL thread, destroys the core,
     * then cools down before another [GLRetroView] may be created.
     */
    fun teardown(
        view: GLRetroView,
        coreName: String?,
        beforeDestroy: () -> Unit = {},
    ) {
        synchronized(sessionLock) {
            Log.i(TAG, "Tearing down core=$coreName")
            beforeDestroy()

            abortPendingFrames(view)
            view.onPause()
            pauseEmulationOnGlThread(view)
            drainGlThread(view)

            // PPSSPP (GLES hw core) must destroy on the GL thread while the EGL
            // context is still valid. removeObserver() calls destroy on the main thread
            // and leaves PPSSPP in a bad state that aborts on the next core load.
            destroyCoreOnGlThread(view)
            drainGlThread(view)

            val cooldown =
                if (coreName in heavyCores) {
                    HEAVY_COOLDOWN_MS
                } else {
                    DEFAULT_COOLDOWN_MS
                }
            if (cooldown > 0) {
                Thread.sleep(cooldown)
            }

            sessionActive = false
            (sessionLock as Object).notifyAll()
            Log.i(TAG, "Teardown complete for core=$coreName")
        }
    }

    /**
     * Prevents [GLRetroView.Renderer.onDrawFrame] from calling [LibretroDroid.step]
     * while we tear down the native core.
     */
    private fun abortPendingFrames(view: GLRetroView) {
        runCatching {
            val readyField = GLRetroView::class.java.getDeclaredField("isEmulationReady")
            readyField.isAccessible = true
            readyField.setBoolean(view, false)
            val abortedField = GLRetroView::class.java.getDeclaredField("isAborted")
            abortedField.isAccessible = true
            abortedField.setBoolean(view, true)
        }.onFailure {
            Log.w(TAG, "Could not flag GLRetroView aborted: $it")
        }
    }

    private fun destroyCoreOnGlThread(view: GLSurfaceView) {
        val latch = CountDownLatch(1)
        var destroyFailed = false
        view.queueEvent {
            try {
                LibretroDroid.destroy()
                Log.i(TAG, "LibretroDroid.destroy() completed on GL thread")
            } catch (e: Exception) {
                destroyFailed = true
                Log.e(TAG, "LibretroDroid.destroy() failed on GL thread: $e")
            } finally {
                latch.countDown()
            }
        }
        if (!latch.await(GL_DRAIN_TIMEOUT_SEC, TimeUnit.SECONDS)) {
            Log.w(TAG, "GL destroy timed out after ${GL_DRAIN_TIMEOUT_SEC}s")
        } else if (destroyFailed) {
            Log.w(TAG, "GL destroy reported failure; continuing teardown")
        }
    }

    private fun pauseEmulationOnGlThread(view: GLSurfaceView) {
        val latch = CountDownLatch(1)
        view.queueEvent {
            runCatching { LibretroDroid.pause() }
                .onFailure { Log.w(TAG, "LibretroDroid.pause before teardown failed: $it") }
            latch.countDown()
        }
        if (!latch.await(GL_DRAIN_TIMEOUT_SEC, TimeUnit.SECONDS)) {
            Log.w(TAG, "GL pause drain timed out after ${GL_DRAIN_TIMEOUT_SEC}s")
        }
    }

    private fun drainGlThread(view: GLSurfaceView) {
        val latch = CountDownLatch(1)
        view.queueEvent { latch.countDown() }
        if (!latch.await(GL_DRAIN_TIMEOUT_SEC, TimeUnit.SECONDS)) {
            Log.w(TAG, "GL thread drain timed out after ${GL_DRAIN_TIMEOUT_SEC}s")
        }
    }
}
