package com.omisu.streaming

import android.app.Activity
import android.graphics.Rect
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.util.Size
import android.view.Gravity
import android.view.TextureView
import android.view.ViewGroup
import android.widget.FrameLayout

/**
 * Front camera preview on the activity; [previewTexture] is copied into the stream.
 */
object FaceCamCapture {
    private const val TAG = "FaceCamCapture"

    @Volatile
    private var enabled = false

    @Volatile
    private var tearingDown = false

    private var cameraThread: HandlerThread? = null
    private var cameraHandler: Handler? = null
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null

    @Volatile
    var previewTexture: TextureView? = null
        private set

    private var corner = "bottomRight"
    private var sizePreset = "medium"

    fun isActive(): Boolean = enabled

    fun start(
        activity: Activity,
        corner: String,
        size: String,
    ) {
        stop()
        enabled = true
        this.corner = corner
        this.sizePreset = size

        val thread = HandlerThread("FaceCamCapture").also { it.start() }
        cameraThread = thread
        cameraHandler = Handler(thread.looper)

        val texture = createPreviewView(activity)
        previewTexture = texture
        if (texture.isAvailable) {
            texture.surfaceTexture?.let { st ->
                cameraHandler?.post { openFrontCamera(activity, st) }
            }
        }
        texture.surfaceTextureListener =
            object : TextureView.SurfaceTextureListener {
                override fun onSurfaceTextureAvailable(
                    surface: SurfaceTexture,
                    width: Int,
                    height: Int,
                ) {
                    cameraHandler?.post { openFrontCamera(activity, surface) }
                }

                override fun onSurfaceTextureSizeChanged(
                    surface: SurfaceTexture,
                    width: Int,
                    height: Int,
                ) = Unit

                override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
                    releaseCameraHardware()
                    return true
                }

                override fun onSurfaceTextureUpdated(surface: SurfaceTexture) = Unit
            }
    }

    fun stop() {
        if (tearingDown) return
        tearingDown = true
        enabled = false
        releaseCameraHardware()
        val view = previewTexture
        previewTexture = null
        view?.surfaceTextureListener = null
        view?.let { texture ->
            val parent = texture.parent as? ViewGroup
            if (parent != null) {
                parent.removeView(texture)
            }
        }
        cameraThread?.quitSafely()
        cameraThread = null
        cameraHandler = null
        tearingDown = false
    }

    private fun releaseCameraHardware() {
        try {
            captureSession?.close()
        } catch (_: Exception) {
        }
        captureSession = null
        try {
            cameraDevice?.close()
        } catch (_: Exception) {
        }
        cameraDevice = null
    }

    private fun createPreviewView(activity: Activity): TextureView {
        val edgeDp =
            when (sizePreset) {
                "small" -> 96
                "large" -> 160
                else -> 120
            }
        val density = activity.resources.displayMetrics.density
        val edgePx = (edgeDp * density).toInt()

        val texture = TextureView(activity)
        val params =
            FrameLayout.LayoutParams(edgePx, edgePx).apply {
                gravity =
                    when (corner) {
                        "bottomLeft" -> Gravity.BOTTOM or Gravity.START
                        "topRight" -> Gravity.TOP or Gravity.END
                        "topLeft" -> Gravity.TOP or Gravity.START
                        else -> Gravity.BOTTOM or Gravity.END
                    }
                marginStart = (12 * density).toInt()
                marginEnd = (12 * density).toInt()
                topMargin = (12 * density).toInt()
                bottomMargin = (12 * density).toInt()
            }
        val root = activity.window.decorView as ViewGroup
        root.addView(texture, params)
        return texture
    }

    private fun openFrontCamera(activity: Activity, surfaceTexture: SurfaceTexture) {
        val manager = activity.getSystemService(CameraManager::class.java)
        val cameraId =
            manager.cameraIdList.firstOrNull { id ->
                manager.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING) ==
                    CameraCharacteristics.LENS_FACING_FRONT
            } ?: run {
                Log.e(TAG, "No front camera")
                return
            }

        val characteristics = manager.getCameraCharacteristics(cameraId)
        val map =
            characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
                ?: return
        val previewSize = chooseSize(map.getOutputSizes(SurfaceTexture::class.java))
        surfaceTexture.setDefaultBufferSize(previewSize.width, previewSize.height)
        val previewSurface = android.view.Surface(surfaceTexture)

        manager.openCamera(
            cameraId,
            object : CameraDevice.StateCallback() {
                override fun onOpened(device: CameraDevice) {
                    cameraDevice = device
                    device.createCaptureSession(
                        listOf(previewSurface),
                        object : CameraCaptureSession.StateCallback() {
                            override fun onConfigured(session: CameraCaptureSession) {
                                captureSession = session
                                val request =
                                    device.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
                                        .apply {
                                            addTarget(previewSurface)
                                            set(
                                                CaptureRequest.CONTROL_MODE,
                                                CaptureRequest.CONTROL_MODE_AUTO,
                                            )
                                        }
                                session.setRepeatingRequest(
                                    request.build(),
                                    null,
                                    cameraHandler,
                                )
                            }

                            override fun onConfigureFailed(session: CameraCaptureSession) {
                                Log.e(TAG, "Camera session configure failed")
                            }
                        },
                        cameraHandler,
                    )
                }

                override fun onDisconnected(device: CameraDevice) {
                    device.close()
                }

                override fun onError(device: CameraDevice, error: Int) {
                    Log.e(TAG, "Camera error $error")
                    device.close()
                }
            },
            cameraHandler,
        )
    }

    private fun chooseSize(choices: Array<Size>): Size {
        val target = 640
        return choices.minByOrNull { kotlin.math.abs(it.width - target) } ?: choices.first()
    }

    fun overlayDstRect(canvasW: Int, canvasH: Int): Rect {
        val margin = (canvasW * 0.02f).toInt().coerceAtLeast(8)
        val edgeFrac =
            when (sizePreset) {
                "small" -> 0.15f
                "large" -> 0.28f
                else -> 0.2f
            }
        val edge = (canvasW * edgeFrac).toInt().coerceIn(96, 480)
        return when (corner) {
            "bottomLeft" ->
                Rect(margin, canvasH - edge - margin, margin + edge, canvasH - margin)
            "topRight" ->
                Rect(canvasW - edge - margin, margin, canvasW - margin, margin + edge)
            "topLeft" -> Rect(margin, margin, margin + edge, margin + edge)
            else ->
                Rect(
                    canvasW - edge - margin,
                    canvasH - edge - margin,
                    canvasW - margin,
                    canvasH - margin,
                )
        }
    }
}
