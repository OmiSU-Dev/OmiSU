package com.omisu.streaming

import android.app.Notification
import android.app.PendingIntent
import android.content.Intent
import android.media.projection.MediaProjection
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.lifecycle.lifecycleScope
import com.omisu.launcher.R
import io.github.thibaultbee.streampack.core.elements.sources.audio.IAudioSourceInternal
import io.github.thibaultbee.streampack.core.elements.sources.audio.audiorecord.MediaProjectionAudioSourceFactory
import io.github.thibaultbee.streampack.core.elements.sources.audio.audiorecord.MicrophoneSourceFactory
import io.github.thibaultbee.streampack.core.elements.sources.video.IVideoSourceInternal
import io.github.thibaultbee.streampack.core.elements.sources.video.mediaprojection.MediaProjectionVideoSourceFactory
import io.github.thibaultbee.streampack.core.interfaces.ICloseableStreamer
import io.github.thibaultbee.streampack.core.streamers.single.ISingleStreamer
import io.github.thibaultbee.streampack.services.MediaProjectionService
import io.github.thibaultbee.streampack.services.utils.SingleStreamerFactory
import kotlinx.coroutines.launch

class OmisuStreamingService :
    MediaProjectionService<ISingleStreamer>(
        streamerFactory =
            SingleStreamerFactory(
                withAudio = true,
                withVideo = true,
            ),
        notificationId = 0x4F4D49,
        channelId = "com.omisu.launcher.streaming",
        channelNameResourceId = R.string.streaming_notification_channel,
        notificationIconResourceId = R.mipmap.launcher_icon,
    ) {
    override fun createDefaultVideoSource(
        mediaProjection: MediaProjection,
        extras: Bundle,
    ): IVideoSourceInternal.Factory? {
        return if (EmbeddedStreamCapture.isActive()) {
            EmbeddedRetroVideoSourceFactory()
        } else {
            MediaProjectionVideoSourceFactory(mediaProjection)
        }
    }

    override fun createDefaultAudioSource(
        mediaProjection: MediaProjection,
        extras: Bundle,
    ): IAudioSourceInternal.Factory? = when (extras.getString(AUDIO_SOURCE_KEY)) {
        AUDIO_SOURCE_MIXED_KEY ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MixedGameMicAudioSourceFactory(mediaProjection)
            } else {
                MicrophoneSourceFactory()
            }
        AUDIO_SOURCE_MEDIA_PROJECTION_KEY ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaProjectionAudioSourceFactory(mediaProjection)
            } else {
                MicrophoneSourceFactory()
            }
        else -> MicrophoneSourceFactory()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            lifecycleScope.launch {
                try {
                    streamer.stopStream()
                    (streamer as? ICloseableStreamer)?.close()
                } catch (_: Exception) {
                }
                StreamingController.onStreamStoppedFromNotification()
            }
        }
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onOpenNotification(): Notification {
        val intent =
            Intent(this, OmisuStreamingService::class.java).setAction(ACTION_STOP)
        val stopIntent =
            PendingIntent.getService(this, 5679, intent, PendingIntent.FLAG_IMMUTABLE)

        return NotificationCompat.Builder(this, channelId)
            .setSmallIcon(notificationIconResourceId)
            .setContentTitle(getString(R.string.streaming_live_title))
            .setContentText(getString(R.string.streaming_live_body))
            .addAction(
                android.R.drawable.ic_media_pause,
                getString(R.string.streaming_stop_action),
                stopIntent,
            )
            .setOngoing(true)
            .build()
    }

    companion object {
        const val ACTION_STOP = "com.omisu.streaming.STOP"
        const val AUDIO_SOURCE_KEY = "audioSource"
        const val AUDIO_SOURCE_MEDIA_PROJECTION_KEY = "mediaProjection"
        const val AUDIO_SOURCE_MICROPHONE_KEY = "microphone"
        const val AUDIO_SOURCE_MIXED_KEY = "mixed"
    }
}
