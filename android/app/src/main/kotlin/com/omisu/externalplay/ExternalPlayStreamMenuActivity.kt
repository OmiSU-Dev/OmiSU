package com.omisu.externalplay

import android.app.Activity
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.KeyEvent
import android.view.Surface
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.omisu.streaming.FaceCamCapture
import com.omisu.streaming.StreamStartConfig
import com.omisu.streaming.StreamingController
import com.omisu.streaming.StreamingState
import io.github.thibaultbee.streampack.core.streamers.utils.MediaProjectionUtils

/**
 * In-game stream controls for Android / Play Store titles (Phase 2).
 * Opened from the accessibility service on controller Start/Menu while
 * [ExternalPlaySessionHelper.isActive].
 */
class ExternalPlayStreamMenuActivity : Activity() {
    private var pendingStartAfterProjection = false
    private var statusText: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        applyLandscapeOrientationMatchingDisplay()
        super.onCreate(savedInstanceState)
        ExternalPlaySessionHelper.isMenuVisible = true
        val title =
            intent.getStringExtra(EXTRA_GAME_TITLE)
                ?: ExternalPlaySessionHelper.gameTitle

        val root = ScrollView(this)
        val column =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(48, 48, 48, 48)
            }
        root.addView(column)

        column.addView(
            TextView(this).apply {
                text = title
                textSize = 22f
                setTextColor(0xFFFFFFFF.toInt())
                gravity = Gravity.CENTER_HORIZONTAL
            },
        )
        statusText =
            TextView(this).apply {
                text = streamStatusLabel()
                textSize = 14f
                setTextColor(0xFFAAAAAA.toInt())
                setPadding(0, 16, 0, 24)
            }
        column.addView(statusText)

        fun addButton(label: String, onClick: () -> Unit) {
            column.addView(
                Button(this).apply {
                    text = label
                    setOnClickListener { onClick() }
                },
            )
        }

        addButton("Start stream") { requestStartStream() }
        addButton("Stop stream") {
            StreamingController.stopStream { refreshStatus() }
        }
        addButton("Toggle microphone") {
            val settings = StreamSettingsReader.load(this)
            StreamSettingsReader.saveMic(this, !settings.includeMicrophone)
            refreshStatus()
        }
        addButton("Toggle face camera") {
            val settings = StreamSettingsReader.load(this)
            val next = !settings.faceCamEnabled
            StreamSettingsReader.saveFaceCam(this, next)
            if (StreamingController.isStreaming()) {
                if (next) {
                    FaceCamCapture.start(this, settings.faceCamCorner, settings.faceCamSize)
                } else {
                    FaceCamCapture.stop()
                }
            }
            refreshStatus()
        }
        addButton("Resume game") { finish() }

        setContentView(root)
        window.setBackgroundDrawableResource(android.R.color.black)
    }

    private fun applyLandscapeOrientationMatchingDisplay() {
        when (display?.rotation) {
            Surface.ROTATION_90 ->
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
            Surface.ROTATION_270 ->
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE
            else -> {
                val fromLaunch = ExternalPlaySessionHelper.menuLandscapeOrientation
                requestedOrientation =
                    if (fromLaunch != ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE) {
                        fromLaunch
                    } else {
                        ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                    }
            }
        }
    }

    private fun streamStatusLabel(): String {
        val settings = StreamSettingsReader.load(this)
        val streamState = StreamingController.state.name
        val mic = if (settings.includeMicrophone) "on" else "off"
        val cam = if (settings.faceCamEnabled) "on" else "off"
        return "Stream: $streamState • Mic: $mic • Face cam: $cam"
    }

    private fun refreshStatus() {
        statusText?.text = streamStatusLabel()
    }

    private fun requestStartStream() {
        val settings = StreamSettingsReader.load(this)
        if (settings.ingestUri.isBlank()) {
            statusText?.text = "Configure RTMP in OmiSU Streaming settings first"
            return
        }
        if (StreamingController.isStreaming()) {
            refreshStatus()
            return
        }
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.RECORD_AUDIO),
                REQUEST_AUDIO,
            )
            return
        }
        if (settings.faceCamEnabled &&
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.CAMERA) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.CAMERA),
                REQUEST_CAMERA,
            )
            return
        }
        launchProjectionPicker()
    }

    private fun launchProjectionPicker() {
        pendingStartAfterProjection = true
        @Suppress("DEPRECATION")
        startActivityForResult(
            MediaProjectionUtils.createScreenCaptureIntent(this),
            REQUEST_PROJECTION,
        )
    }

    private fun startStreamWithProjection(resultCode: Int, data: android.content.Intent) {
        val settings = StreamSettingsReader.load(this)
        val config =
            StreamStartConfig(
                rtmpUrl = settings.ingestUri,
                width = settings.width,
                height = settings.height,
                bitrateKbps = settings.bitrateKbps,
                qualityPreset = settings.qualityPreset,
                audioMode = settings.audioMode,
                faceCamEnabled = settings.faceCamEnabled,
                faceCamCorner = settings.faceCamCorner,
                faceCamSize = settings.faceCamSize,
            )
        StreamingController.bindAndStart(
            context = this,
            resultCode = resultCode,
            resultData = data,
            config = config,
            onSuccess = { refreshStatus() },
            onError = { msg -> statusText?.text = msg },
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (grantResults.isEmpty() || grantResults[0] != PackageManager.PERMISSION_GRANTED) {
            statusText?.text = "Permission required for streaming"
            return
        }
        when (requestCode) {
            REQUEST_AUDIO, REQUEST_CAMERA -> requestStartStream()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PROJECTION || !pendingStartAfterProjection) return
        pendingStartAfterProjection = false
        if (resultCode != Activity.RESULT_OK || data == null) {
            statusText?.text = "Screen capture permission denied"
            return
        }
        startStreamWithProjection(resultCode, data)
    }

    override fun onDestroy() {
        ExternalPlaySessionHelper.isMenuVisible = false
        super.onDestroy()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN &&
            event.keyCode == KeyEvent.KEYCODE_BACK
        ) {
            finish()
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    companion object {
        const val EXTRA_GAME_TITLE = "game_title"
        private const val REQUEST_AUDIO = 0xE001
        private const val REQUEST_CAMERA = 0xE002
        private const val REQUEST_PROJECTION = 0xE003
    }
}
