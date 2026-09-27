package com.omisu.streaming

import android.Manifest
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTimestamp
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.annotation.RequiresPermission
import io.github.thibaultbee.streampack.core.elements.sources.audio.AudioSourceConfig
import io.github.thibaultbee.streampack.core.elements.sources.audio.IAudioSourceInternal
import io.github.thibaultbee.streampack.core.elements.utils.time.TimeUtils
import java.nio.ByteBuffer
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Captures in-game / app playback audio via [MediaProjection] (Android 10+). */
@RequiresApi(Build.VERSION_CODES.Q)
internal class GamePlaybackAudioSource(
    private val appContext: Context,
    private val mediaProjection: MediaProjection,
) : IAudioSourceInternal {
    private var gameRecord: AudioRecord? = null
    private val _isStreamingFlow = MutableStateFlow(false)
    override val isStreamingFlow = _isStreamingFlow.asStateFlow()

    override val minBufferSize: Int
        get() = _minBufferSize
    private var _minBufferSize: Int = 0

    private val audioTimestamp = AudioTimestamp()

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    override suspend fun configure(config: AudioSourceConfig) {
        release()
        _minBufferSize =
            AudioRecord.getMinBufferSize(
                config.sampleRate,
                config.channelConfig,
                config.byteFormat,
            ).coerceAtLeast(4096)

        val audioFormat =
            AudioFormat.Builder()
                .setEncoding(config.byteFormat)
                .setSampleRate(config.sampleRate)
                .setChannelMask(config.channelConfig)
                .build()

        val playbackConfig = PlaybackCaptureConfig.build(mediaProjection, appContext)
        gameRecord =
            AudioRecord.Builder()
                .setAudioFormat(audioFormat)
                .setBufferSizeInBytes(_minBufferSize * 4)
                .setAudioPlaybackCaptureConfig(playbackConfig)
                .build()

        if (gameRecord?.state != AudioRecord.STATE_INITIALIZED) {
            gameRecord?.release()
            gameRecord = null
            Log.e(TAG, "Game playback AudioRecord failed to initialize")
            throw IllegalArgumentException(
                "Could not capture game audio. Enable Include microphone or check Android version.",
            )
        }
        Log.i(TAG, "Game playback capture initialized (buffer=$_minBufferSize)")
    }

    override suspend fun startStream() {
        gameRecord?.startRecording()
        _isStreamingFlow.emit(true)
    }

    override suspend fun stopStream() {
        gameRecord?.stop()
        _isStreamingFlow.emit(false)
    }

    override fun release() {
        gameRecord?.release()
        gameRecord = null
        _isStreamingFlow.tryEmit(false)
    }

    override fun fillAudioFrame(buffer: ByteBuffer): Long {
        val record = gameRecord ?: throw IllegalStateException("Game audio not initialized")
        buffer.clear()
        val read = record.read(buffer, buffer.remaining())
        if (read <= 0) {
            buffer.limit(0)
        }
        return readTimestamp(record)
    }

    private fun readTimestamp(audioRecord: AudioRecord): Long {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            if (audioRecord.getTimestamp(
                    audioTimestamp,
                    AudioTimestamp.TIMEBASE_MONOTONIC,
                ) == AudioRecord.SUCCESS
            ) {
                return audioTimestamp.nanoTime / 1000
            }
        }
        return TimeUtils.currentTime()
    }

    companion object {
        private const val TAG = "GamePlaybackAudio"
    }
}

@RequiresApi(Build.VERSION_CODES.Q)
class GamePlaybackAudioSourceFactory(
    private val mediaProjection: MediaProjection,
) : IAudioSourceInternal.Factory {
    override suspend fun create(context: Context): IAudioSourceInternal =
        GamePlaybackAudioSource(context.applicationContext, mediaProjection)

    override fun isSourceEquals(source: IAudioSourceInternal?): Boolean =
        source is GamePlaybackAudioSource
}
