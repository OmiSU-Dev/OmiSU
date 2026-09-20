package com.omisu.streaming

import android.Manifest
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.AudioTimestamp
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.annotation.RequiresPermission
import android.content.Context
import android.util.Log
import io.github.thibaultbee.streampack.core.elements.sources.audio.AudioSourceConfig
import io.github.thibaultbee.streampack.core.elements.sources.audio.IAudioSourceInternal
import io.github.thibaultbee.streampack.core.elements.utils.time.TimeUtils
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Mixes in-app playback (game) with the device microphone into one AAC-bound PCM stream.
 */
@RequiresApi(Build.VERSION_CODES.Q)
internal class MixedGameMicAudioSource(
    private val mediaProjection: MediaProjection,
) : IAudioSourceInternal {
    private var gameRecord: AudioRecord? = null
    private var micRecord: AudioRecord? = null
    private var scratchGame = ByteArray(0)
    private var scratchMic = ByteArray(0)

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

        micRecord =
            AudioRecord.Builder()
                .setAudioFormat(audioFormat)
                .setBufferSizeInBytes(_minBufferSize * 2)
                .setAudioSource(MediaRecorder.AudioSource.MIC)
                .build()

        if (micRecord?.state != AudioRecord.STATE_INITIALIZED) {
            release()
            throw IllegalArgumentException("Failed to initialize microphone capture")
        }

        try {
            val playbackConfig =
                AudioPlaybackCaptureConfiguration.Builder(mediaProjection)
                    .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                    .addMatchingUsage(AudioAttributes.USAGE_GAME)
                    .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                    .build()
            gameRecord =
                AudioRecord.Builder()
                    .setAudioFormat(audioFormat)
                    .setBufferSizeInBytes(_minBufferSize * 2)
                    .setAudioPlaybackCaptureConfig(playbackConfig)
                    .build()
            if (gameRecord?.state != AudioRecord.STATE_INITIALIZED) {
                gameRecord?.release()
                gameRecord = null
                Log.w(TAG, "Game playback capture unavailable; streaming mic-forward mix")
            }
        } catch (t: Throwable) {
            Log.w(TAG, "Game playback capture failed: ${t.message}")
            gameRecord = null
        }

        scratchGame = ByteArray(_minBufferSize * 2)
        scratchMic = ByteArray(_minBufferSize * 2)
    }

    override suspend fun startStream() {
        micRecord?.startRecording()
        gameRecord?.startRecording()
        _isStreamingFlow.emit(true)
    }

    override suspend fun stopStream() {
        gameRecord?.stop()
        micRecord?.stop()
        _isStreamingFlow.emit(false)
    }

    override fun release() {
        gameRecord?.release()
        micRecord?.release()
        gameRecord = null
        micRecord = null
        _isStreamingFlow.tryEmit(false)
    }

    override fun fillAudioFrame(buffer: ByteBuffer): Long {
        val mic = micRecord ?: throw IllegalStateException("Mic audio not initialized")
        val bytes = buffer.remaining()
        if (scratchMic.size < bytes) {
            scratchMic = ByteArray(bytes)
            scratchGame = ByteArray(bytes)
        }
        buffer.clear()
        val mRead = mic.read(scratchMic, 0, bytes).coerceAtLeast(0)
        val gRead =
            gameRecord?.read(scratchGame, 0, bytes)?.coerceAtLeast(0) ?: 0
        val samples = (maxOf(mRead, gRead) / 2).coerceAtLeast(0)
        val gameSamples = ByteBuffer.wrap(scratchGame).order(ByteOrder.LITTLE_ENDIAN)
        val micSamples = ByteBuffer.wrap(scratchMic).order(ByteOrder.LITTLE_ENDIAN)
        buffer.order(ByteOrder.LITTLE_ENDIAN)
        for (i in 0 until samples) {
            val off = i * 2
            val g =
                if (off + 1 < gRead) {
                    gameSamples.getShort(off).toInt()
                } else {
                    0
                }
            val m =
                if (off + 1 < mRead) {
                    micSamples.getShort(off).toInt()
                } else {
                    0
                }
            var mix = g + (m * 3) / 2
            if (mix > 32767) mix = 32767
            if (mix < -32768) mix = -32768
            buffer.putShort(mix.toShort())
        }
        buffer.flip()
        return readTimestamp(mic)
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
        private const val TAG = "MixedGameMicAudio"
    }
}

@RequiresApi(Build.VERSION_CODES.Q)
class MixedGameMicAudioSourceFactory(
    private val mediaProjection: MediaProjection,
) : IAudioSourceInternal.Factory {
    override suspend fun create(context: Context): IAudioSourceInternal =
        MixedGameMicAudioSource(mediaProjection)

    override fun isSourceEquals(source: IAudioSourceInternal?): Boolean =
        source is MixedGameMicAudioSource
}
