package com.omisu.streaming

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.media.MediaCodecInfo.CodecProfileLevel.AVCProfileMain
import android.media.MediaFormat
import android.os.IBinder
import android.util.Log
import android.util.Range
import android.util.Size
import io.github.thibaultbee.streampack.core.configuration.BitrateRegulatorConfig
import io.github.thibaultbee.streampack.core.regulator.controllers.intervalBitrateRegulatorControllerFactory
import androidx.core.net.toUri
import io.github.thibaultbee.streampack.core.configuration.mediadescriptor.UriMediaDescriptor
import io.github.thibaultbee.streampack.core.elements.encoders.mediacodec.MediaCodecHelper
import io.github.thibaultbee.streampack.core.interfaces.ICloseableStreamer
import io.github.thibaultbee.streampack.core.interfaces.IOpenableStreamer
import io.github.thibaultbee.streampack.core.streamers.IConfigurableAudioStreamer
import io.github.thibaultbee.streampack.core.streamers.IVideoStreamer
import io.github.thibaultbee.streampack.core.streamers.single.AudioConfig
import io.github.thibaultbee.streampack.core.streamers.single.IAudioSingleStreamer
import io.github.thibaultbee.streampack.core.streamers.single.ISingleStreamer
import io.github.thibaultbee.streampack.core.streamers.single.IVideoSingleStreamer
import io.github.thibaultbee.streampack.core.streamers.single.VideoConfig
import io.github.thibaultbee.streampack.services.MediaProjectionService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

data class StreamStartConfig(
    val rtmpUrl: String,
    val width: Int = 1280,
    val height: Int = 720,
    val bitrateKbps: Int = 4000,
    val fps: Int = 30,
    val audioMode: StreamAudioMode = StreamAudioMode.GAME,
    val faceCamEnabled: Boolean = false,
    val faceCamCorner: String = "bottomRight",
    val faceCamSize: String = "medium",
)

enum class StreamingState {
    IDLE,
    STARTING,
    LIVE,
    ERROR,
}

object StreamingController {
    private const val TAG = "StreamingController"

    private const val VIDEO_GOP_SECONDS = 2f
    private const val MAX_STREAM_FPS = 30
    private const val AUDIO_BITRATE_BPS = 96_000

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val stopMutex = Mutex()

    @Volatile
    var state: StreamingState = StreamingState.IDLE
        private set

    @Volatile
    var lastError: String? = null
        private set

    var stateListener: ((StreamingState, String?) -> Unit)? = null

    private var appContext: Context? = null
    private var connection: ServiceConnection? = null
    private var streamer: ISingleStreamer? = null
    fun isStreaming(): Boolean = state == StreamingState.LIVE

    fun onStreamStoppedFromNotification() {
        scope.launch {
            tearDown(stopStreamer = false)
            emitState(StreamingState.IDLE, null)
        }
    }

    private fun emitState(newState: StreamingState, message: String?) {
        state = newState
        if (newState != StreamingState.ERROR) {
            lastError = null
        } else {
            lastError = message
        }
        stateListener?.invoke(newState, message)
    }

    fun bindAndStart(
        context: Context,
        resultCode: Int,
        resultData: Intent,
        config: StreamStartConfig,
        onSuccess: () -> Unit,
        onError: (String) -> Unit,
    ) {
        if (state == StreamingState.LIVE || state == StreamingState.STARTING) {
            onError("Stream already active")
            return
        }

        appContext = context.applicationContext
        emitState(StreamingState.STARTING, null)

        val audioExtraKey = resolveAudioSourceKey(config.audioMode)

        connection =
            MediaProjectionService.bindService(
                context = context,
                serviceClass = OmisuStreamingService::class.java,
                resultCode = resultCode,
                resultData = resultData,
                onServiceCreated = { createdStreamer ->
                    streamer = createdStreamer as ISingleStreamer
                    scope.launch {
                        try {
                            configureAndStart(createdStreamer as ISingleStreamer, config)
                            if (config.faceCamEnabled) {
                                val activity = context as? Activity
                                if (activity != null) {
                                    FaceCamCapture.start(
                                        activity,
                                        config.faceCamCorner,
                                        config.faceCamSize,
                                    )
                                } else {
                                    Log.w(TAG, "Face cam requested but context is not an Activity")
                                }
                            }
                            emitState(StreamingState.LIVE, null)
                            onSuccess()
                        } catch (t: Throwable) {
                            Log.e(TAG, "Failed to start stream", t)
                            tearDown(stopStreamer = true)
                            emitState(StreamingState.ERROR, t.message ?: "Stream failed")
                            onError(t.message ?: "Stream failed")
                        }
                    }
                },
                onServiceDisconnected = {
                    streamer = null
                    emitState(StreamingState.IDLE, null)
                },
                onExtra = { extra ->
                    extra.putExtra(OmisuStreamingService.AUDIO_SOURCE_KEY, audioExtraKey)
                },
            )
    }

    private suspend fun configureAndStart(
        streamer: ISingleStreamer,
        config: StreamStartConfig,
    ) {
        val videoStreamer = streamer as? IVideoStreamer<*>
            ?: throw IllegalStateException("Streamer does not support video")

        val encodeSize = alignEncodeResolution(config.width, config.height)
        val targetVideoBitrateBps = clampVideoBitrate(config.bitrateKbps, encodeSize)

        val fps =
            config.fps.coerceIn(24, MAX_STREAM_FPS).let { requested ->
                if (MediaCodecHelper.Video.getFramerateRange(MediaFormat.MIMETYPE_VIDEO_AVC)
                        .contains(requested)
                ) {
                    requested
                } else {
                    MAX_STREAM_FPS
                }
            }

        val videoConfig =
            VideoConfig(
                mimeType = MediaFormat.MIMETYPE_VIDEO_AVC,
                startBitrate = targetVideoBitrateBps,
                resolution = encodeSize,
                fps = fps,
                gopDurationInS = VIDEO_GOP_SECONDS,
                profile = AVCProfileMain,
            )

        withContext(Dispatchers.Main) {
            when (videoStreamer) {
                is IVideoSingleStreamer -> videoStreamer.setVideoConfig(videoConfig)
                else -> throw IllegalStateException("Unsupported video streamer type")
            }
        }

        val audioStreamer = streamer as? IConfigurableAudioStreamer<*>
        if (audioStreamer != null) {
            val audioConfig =
                AudioConfig(
                    mimeType = MediaFormat.MIMETYPE_AUDIO_AAC,
                    startBitrate = AUDIO_BITRATE_BPS,
                    sampleRate = 48_000,
                    channelConfig = AudioConfig.getChannelConfig(2),
                    byteFormat = 2,
                )
            withContext(Dispatchers.Main) {
                when (streamer) {
                    is IAudioSingleStreamer -> streamer.setAudioConfig(audioConfig)
                    else -> throw IllegalStateException("Unsupported audio streamer type")
                }
            }
        }

        val minVideoBitrate = (targetVideoBitrateBps * 0.45f).toInt().coerceAtLeast(600_000)
        (videoStreamer as? IVideoSingleStreamer)?.bitrateRegulatorControllerFactory =
            intervalBitrateRegulatorControllerFactory(
                bitrateRegulatorConfig =
                    BitrateRegulatorConfig(
                        videoBitrateRange = Range(minVideoBitrate, targetVideoBitrateBps),
                        audioBitrateRange = Range(AUDIO_BITRATE_BPS, AUDIO_BITRATE_BPS),
                    ),
            )

        Log.i(
            TAG,
            "RTMP encode ${encodeSize.width}x${encodeSize.height} @ ${fps}fps, " +
                "${targetVideoBitrateBps / 1000}kbps video (min ${minVideoBitrate / 1000}), " +
                "gop=${VIDEO_GOP_SECONDS}s",
        )

        val descriptor = UriMediaDescriptor(config.rtmpUrl.toUri())
        val openable =
            streamer as? IOpenableStreamer
                ?: throw IllegalStateException("Streamer does not support RTMP open")
        openable.open(descriptor)
        openable.startStream()
    }

    fun stopStream(onComplete: ((Boolean) -> Unit)? = null) {
        scope.launch {
            val ok =
                try {
                    stopStreamAndAwait()
                    true
                } catch (t: Throwable) {
                    Log.e(TAG, "Failed to stop stream", t)
                    false
                }
            onComplete?.invoke(ok)
        }
    }

    suspend fun stopStreamAndAwait() {
        stopMutex.withLock {
            if (state == StreamingState.IDLE && streamer == null && connection == null) {
                return
            }
            tearDown(stopStreamer = true)
            emitState(StreamingState.IDLE, null)
        }
    }

    private suspend fun tearDown(stopStreamer: Boolean) {
        withContext(Dispatchers.Main) {
            FaceCamCapture.stop()
        }
        val ctx = appContext
        val activeStreamer = streamer
        val activeConnection = connection

        connection = null
        streamer = null

        if (stopStreamer && activeStreamer != null) {
            try {
                activeStreamer.stopStream()
                (activeStreamer as? ICloseableStreamer)?.close()
            } catch (t: Throwable) {
                Log.w(TAG, "Error stopping streamer: ${t.message}")
            }
        }

        if (ctx != null && activeConnection != null) {
            try {
                ctx.unbindService(activeConnection)
            } catch (t: Throwable) {
                Log.w(TAG, "Error unbinding service: ${t.message}")
            }
            try {
                ctx.stopService(Intent(ctx, OmisuStreamingService::class.java))
            } catch (_: Exception) {
            }
        }
    }

    private fun resolveAudioSourceKey(mode: StreamAudioMode): String {
        return when (mode) {
            StreamAudioMode.MIC -> OmisuStreamingService.AUDIO_SOURCE_MICROPHONE_KEY
            StreamAudioMode.MIXED ->
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    OmisuStreamingService.AUDIO_SOURCE_MIXED_KEY
                } else {
                    OmisuStreamingService.AUDIO_SOURCE_MICROPHONE_KEY
                }
            StreamAudioMode.GAME ->
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    OmisuStreamingService.AUDIO_SOURCE_MEDIA_PROJECTION_KEY
                } else {
                    OmisuStreamingService.AUDIO_SOURCE_MICROPHONE_KEY
                }
        }
    }

    /** Even dimensions, capped for mobile uplink + MediaProjection encoder load. */
    private fun alignEncodeResolution(width: Int, height: Int): Size {
        var w = width.coerceIn(854, 1920)
        var h = height.coerceIn(480, 1080)
        if (w > 1280 && h > 720) {
            val scale = 1280f / w.toFloat()
            w = 1280
            h = (h * scale).toInt().coerceAtMost(720)
        }
        w = w and 0x7FFFFFFE
        h = h and 0x7FFFFFFE
        if (w < 854) w = 854
        if (h < 480) h = 480
        return Size(w, h)
    }

    private fun clampVideoBitrate(bitrateKbps: Int, size: Size): Int {
        val pixels = size.width.toLong() * size.height
        val maxForResolution =
            when {
                pixels > 1280L * 720L -> 4_500_000
                pixels > 960L * 540L -> 3_000_000
                else -> 2_200_000
            }
        val requested = (bitrateKbps.coerceIn(1200, 6000)) * 1000
        return minOf(requested, maxForResolution)
    }
}
