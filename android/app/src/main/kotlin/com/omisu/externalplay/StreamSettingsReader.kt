package com.omisu.externalplay

import android.content.Context
import com.omisu.streaming.StreamQualityResolver

/**
 * Reads global RTMP settings written by Flutter [StreamSettingsService]
 * (`flutter.omisu_stream_*` keys in FlutterSharedPreferences).
 */
object StreamSettingsReader {
    data class Settings(
        val ingestUri: String,
        val width: Int,
        val height: Int,
        val bitrateKbps: Int,
        val fps: Int,
        val qualityPreset: String,
        val audioMode: com.omisu.streaming.StreamAudioMode,
        val faceCamEnabled: Boolean,
        val faceCamCorner: String,
        val faceCamSize: String,
        val includeMicrophone: Boolean,
        val gameAudioEnabled: Boolean,
    )

    fun load(context: Context): Settings {
        val prefs =
            context.applicationContext.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE,
            )
        val server = prefs.getString("flutter.omisu_stream_server", "") ?: ""
        val key = prefs.getString("flutter.omisu_stream_key", "") ?: ""
        val quality = prefs.getString("flutter.omisu_stream_quality", "auto") ?: "auto"
        val gameAudio = prefs.getBoolean("flutter.omisu_stream_game_audio", true)
        val includeMic = prefs.getBoolean("flutter.omisu_stream_include_mic", false)
        val faceCam = prefs.getBoolean("flutter.omisu_stream_face_cam", false)
        val faceCorner = prefs.getString("flutter.omisu_stream_face_corner", "bottomRight") ?: "bottomRight"
        val faceSize = prefs.getString("flutter.omisu_stream_face_size", "medium") ?: "medium"

        val base = server.trim()
        val streamKey = key.trim()
        val ingest =
            when {
                base.isEmpty() || streamKey.isEmpty() -> ""
                base.endsWith("/") -> "$base$streamKey"
                else -> "$base/$streamKey"
            }

        val (w, h, br) = StreamQualityResolver.encodeTriple(context, quality)
        val fps = StreamQualityResolver.fpsFor(context, quality)

        val audioMode =
            when {
                includeMic && gameAudio -> com.omisu.streaming.StreamAudioMode.MIXED
                includeMic -> com.omisu.streaming.StreamAudioMode.MIC
                else -> com.omisu.streaming.StreamAudioMode.GAME
            }

        return Settings(
            ingestUri = ingest,
            width = w,
            height = h,
            bitrateKbps = br,
            fps = fps,
            qualityPreset = quality,
            audioMode = audioMode,
            faceCamEnabled = faceCam,
            faceCamCorner = faceCorner,
            faceCamSize = faceSize,
            includeMicrophone = includeMic,
            gameAudioEnabled = gameAudio,
        )
    }

    fun saveMic(context: Context, enabled: Boolean) {
        val prefs =
            context.applicationContext.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE,
            )
        prefs.edit().putBoolean("flutter.omisu_stream_include_mic", enabled).apply()
    }

    fun saveFaceCam(context: Context, enabled: Boolean) {
        val prefs =
            context.applicationContext.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE,
            )
        prefs.edit().putBoolean("flutter.omisu_stream_face_cam", enabled).apply()
    }
}
