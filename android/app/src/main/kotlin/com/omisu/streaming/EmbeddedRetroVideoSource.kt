package com.omisu.streaming

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Size
import android.view.PixelCopy
import android.view.Surface
import com.swordfish.libretrodroid.GLRetroView
import io.github.thibaultbee.streampack.core.elements.processing.video.source.DefaultSourceInfoProvider
import io.github.thibaultbee.streampack.core.elements.processing.video.source.ISourceInfoProvider
import io.github.thibaultbee.streampack.core.elements.sources.video.ISurfaceSourceInternal
import io.github.thibaultbee.streampack.core.elements.sources.video.IVideoSourceInternal
import io.github.thibaultbee.streampack.core.elements.sources.video.VideoSourceConfig
import io.github.thibaultbee.streampack.core.elements.utils.time.Timebase
import io.github.thibaultbee.streampack.core.pipelines.IVideoDispatcherProvider
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

internal class EmbeddedRetroVideoSource(
    private val context: Context,
) : IVideoSourceInternal, ISurfaceSourceInternal {
    override val timebase = Timebase.REALTIME

    override val infoProviderFlow =
        MutableStateFlow(
            object : DefaultSourceInfoProvider() {
                override fun getSurfaceSize(targetResolution: Size): Size = targetResolution
            } as ISourceInfoProvider,
        ).asStateFlow()

    private val _isStreamingFlow = MutableStateFlow(false)
    override val isStreamingFlow = _isStreamingFlow.asStateFlow()

    private var outputSurface: Surface? = null
    private var captureBitmap: Bitmap? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var frameRunnable: Runnable? = null
    @Volatile
    private var capturing = false

    private val paint =
        Paint(Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG).apply {
            isAntiAlias = true
        }

    override suspend fun getOutput(): Surface? = outputSurface

    override suspend fun setOutput(surface: Surface) {
        outputSurface = surface
    }

    override suspend fun resetOutput() {
        stopStream()
        outputSurface = null
    }

    override suspend fun configure(config: VideoSourceConfig) = Unit

    override suspend fun startStream() {
        capturing = true
        _isStreamingFlow.emit(true)
        scheduleFrameLoop()
    }

    override suspend fun stopStream() {
        capturing = false
        _isStreamingFlow.emit(false)
        frameRunnable?.let { mainHandler.removeCallbacks(it) }
        frameRunnable = null
    }

    override suspend fun release() {
        stopStream()
        captureBitmap?.recycle()
        captureBitmap = null
    }

    private fun scheduleFrameLoop() {
        val runnable =
            object : Runnable {
                override fun run() {
                    if (!capturing) return
                    val view = EmbeddedStreamCapture.captureView
                    val surface = outputSurface
                    if (view == null || surface == null || !view.isAttachedToWindow) {
                        mainHandler.postDelayed(this, FRAME_INTERVAL_MS)
                        return
                    }
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        mainHandler.postDelayed(this, FRAME_INTERVAL_MS)
                        return
                    }
                    copyViewToEncoder(view, surface) {
                        if (capturing) {
                            mainHandler.postDelayed(this, FRAME_INTERVAL_MS)
                        }
                    }
                }
            }
        frameRunnable = runnable
        mainHandler.post(runnable)
    }

    private fun copyViewToEncoder(
        view: GLRetroView,
        surface: Surface,
        onDone: () -> Unit,
    ) {
        val width = view.width.coerceAtLeast(2)
        val height = view.height.coerceAtLeast(2)
        var bitmap = captureBitmap
        if (bitmap == null || bitmap.width != width || bitmap.height != height) {
            bitmap?.recycle()
            bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            captureBitmap = bitmap
        }
        val faceView = FaceCamCapture.previewTexture
        PixelCopy.request(
            view,
            bitmap,
            { gameResult ->
                if (gameResult == PixelCopy.SUCCESS) {
                    val faceOverlay =
                        if (faceView != null && faceView.isAvailable && FaceCamCapture.isActive()) {
                            faceView.bitmap
                        } else {
                            null
                        }
                    blitToSurface(bitmap, surface, faceOverlay)
                } else {
                    Log.w(TAG, "PixelCopy game failed: $gameResult")
                }
                onDone()
            },
            mainHandler,
        )
    }

    private fun blitToSurface(bitmap: Bitmap, surface: Surface, faceOverlay: Bitmap?) {
        try {
            val canvas: Canvas =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    surface.lockHardwareCanvas()
                } else {
                    @Suppress("DEPRECATION")
                    surface.lockCanvas(null)
                }
            canvas.drawColor(Color.BLACK)
            val dest = Rect(0, 0, canvas.width, canvas.height)
            canvas.drawBitmap(bitmap, null, dest, paint)
            if (faceOverlay != null && FaceCamCapture.isActive()) {
                val dst = FaceCamCapture.overlayDstRect(canvas.width, canvas.height)
                canvas.drawBitmap(faceOverlay, null, dst, paint)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                surface.unlockCanvasAndPost(canvas)
            } else {
                @Suppress("DEPRECATION")
                surface.unlockCanvasAndPost(canvas)
            }
        } catch (t: Throwable) {
            Log.w(TAG, "Encoder surface blit failed: ${t.message}")
        }
    }

    companion object {
        private const val TAG = "EmbeddedRetroVideo"
        private const val FRAME_INTERVAL_MS = 33L
    }
}

class EmbeddedRetroVideoSourceFactory : IVideoSourceInternal.Factory {
    override suspend fun create(
        context: Context,
        dispatcherProvider: IVideoDispatcherProvider,
    ): IVideoSourceInternal = EmbeddedRetroVideoSource(context.applicationContext)

    override fun isSourceEquals(source: IVideoSourceInternal?): Boolean =
        source is EmbeddedRetroVideoSource
}
