package com.omisu.streaming

import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioPlaybackCaptureConfiguration
import android.media.projection.MediaProjection
import android.os.Build
import android.util.Log
import com.omisu.externalplay.ExternalPlaySessionHelper

internal object PlaybackCaptureConfig {
    private const val TAG = "PlaybackCaptureConfig"

    fun build(
        mediaProjection: MediaProjection,
        context: Context,
    ): AudioPlaybackCaptureConfiguration {
        val builder =
            AudioPlaybackCaptureConfiguration.Builder(mediaProjection)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                .addMatchingUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)

        val targetPackage = ExternalPlaySessionHelper.gamePackageName
        if (targetPackage.isNotBlank()) {
            try {
                val uid =
                    context.packageManager.getApplicationInfo(targetPackage, 0).uid
                builder.addMatchingUid(uid)
                Log.i(TAG, "Playback capture targeting uid=$uid ($targetPackage)")
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "Could not resolve uid for $targetPackage: ${e.message}")
            }
        }

        return builder.build()
    }
}
