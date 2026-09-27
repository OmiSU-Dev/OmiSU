package com.omisu.externalplay

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.Surface
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.omisu.launcher.R
import com.omisu.streaming.ExternalPlayStreamCapture
import com.omisu.streaming.OmisuStreamTrace
import com.omisu.streaming.StreamCaptureIntents
import com.omisu.streaming.StreamStartConfig
import com.omisu.streaming.StreamingController

/**
 * Requests screen capture after an external game is in the foreground, then starts RTMP.
 * Shown briefly on top of the game so "share this app only" targets the running title.
 */
class ExternalPlayStreamCaptureActivity : Activity() {
    private var pendingStartAfterProjection = false
    private var settings: StreamSettingsReader.Settings? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        applyLandscapeOrientationMatchingDisplay()
        super.onCreate(savedInstanceState)
        ExternalPlayStreamCapture.recordDisplayFrom(this)
        ExternalPlaySessionHelper.prepareStreamingCapture(
            ExternalPlaySessionHelper.gamePackageName,
        )
        ExternalPlaySessionHelper.isMenuVisible = true

        val gameTitle =
            intent.getStringExtra(EXTRA_GAME_TITLE)
                ?: ExternalPlaySessionHelper.gameTitle

        val column =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(48, 48, 48, 48)
                gravity = Gravity.CENTER
            }
        column.addView(
            TextView(this).apply {
                text = getString(R.string.external_play_stream_capture_message)
                textSize = 16f
                setTextColor(0xFFFFFFFF.toInt())
                gravity = Gravity.CENTER_HORIZONTAL
            },
        )
        setContentView(column)
        window.setBackgroundDrawableResource(android.R.color.black)

        settings = StreamSettingsReader.load(this)
        if (settings!!.ingestUri.isBlank()) {
            OmisuStreamTrace.warn("capture_activity", "no ingest URI — finishing")
            finishCapture()
            return
        }
        OmisuStreamTrace.event(
            "capture_activity_create",
            "game=$gameTitle pkg=${ExternalPlaySessionHelper.gamePackageName} " +
                "quality=${settings!!.qualityPreset} ${settings!!.width}x${settings!!.height} " +
                "${settings!!.fps}fps",
        )
        requestPermissionsThenProjection()
    }

    private fun requestPermissionsThenProjection() {
        val needAudio =
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
        if (needAudio) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.RECORD_AUDIO),
                REQUEST_AUDIO,
            )
            return
        }
        val s = settings ?: return
        if (s.faceCamEnabled &&
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
        OmisuStreamTrace.event("capture_projection_picker", "preferFullDisplay=true")
        @Suppress("DEPRECATION")
        startActivityForResult(
            StreamCaptureIntents.createScreenCaptureIntent(this, preferFullDisplay = true),
            REQUEST_PROJECTION,
        )
    }

    private fun startStreamWithProjection(resultCode: Int, data: Intent) {
        val s = settings ?: return
        val config =
            StreamStartConfig(
                rtmpUrl = s.ingestUri,
                width = s.width,
                height = s.height,
                bitrateKbps = s.bitrateKbps,
                fps = s.fps,
                qualityPreset = s.qualityPreset,
                audioMode = s.audioMode,
                faceCamEnabled = s.faceCamEnabled,
                faceCamCorner = s.faceCamCorner,
                faceCamSize = s.faceCamSize,
            )
        val app = applicationContext
        OmisuStreamTrace.event(
            "capture_post_consent",
            "dismiss overlay → game foreground → RTMP in ${BIND_DELAY_MS}ms",
        )
        bringGameToForeground()
        finishCapture(returnToGame = false)
        mainHandler.postDelayed(
            {
                if (!ExternalPlaySessionHelper.isActive) {
                    OmisuStreamTrace.warn("capture_bind_start", "session ended — skip bind")
                    return@postDelayed
                }
                OmisuStreamTrace.event("capture_bind_start", "resultCode=$resultCode")
                StreamingController.bindAndStart(
                    context = app,
                    resultCode = resultCode,
                    resultData = data,
                    config = config,
                    onSuccess = {
                        OmisuStreamTrace.event("capture_bind_success", "RTMP live on game foreground")
                        ExternalPlaySessionService.refreshNotification(app)
                    },
                    onError = { message ->
                        OmisuStreamTrace.error("capture_bind_failed", message)
                        Toast.makeText(app, message, Toast.LENGTH_LONG).show()
                    },
                )
            },
            BIND_DELAY_MS,
        )
    }

    private fun finishCapture(returnToGame: Boolean = false) {
        OmisuStreamTrace.event("capture_activity_finish", "returnToGame=$returnToGame")
        ExternalPlaySessionHelper.isMenuVisible = false
        finish()
        if (returnToGame) {
            bringGameToForeground()
        }
    }

    private fun bringGameToForeground() {
        val pkg = ExternalPlaySessionHelper.gamePackageName
        if (pkg.isBlank()) {
            OmisuStreamTrace.warn("capture_return_to_game", "no package name")
            return
        }
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        val tasks = am.getRunningTasks(20)
        for (task in tasks) {
            val top = task.topActivity ?: task.baseActivity ?: continue
            if (top.packageName == pkg) {
                am.moveTaskToFront(task.id, ActivityManager.MOVE_TASK_NO_USER_ACTION)
                OmisuStreamTrace.event(
                    "capture_return_to_game",
                    "moveTaskToFront taskId=${task.id} pkg=$pkg",
                )
                return
            }
        }
        val launch =
            packageManager.getLaunchIntentForPackage(pkg)
                ?: run {
                    OmisuStreamTrace.warn("capture_return_to_game", "no launch intent for $pkg")
                    return
                }
        launch.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
        startActivity(launch)
        OmisuStreamTrace.event("capture_return_to_game", "launchIntent pkg=$pkg")
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (grantResults.isEmpty() || grantResults[0] != PackageManager.PERMISSION_GRANTED) {
            OmisuStreamTrace.warn("capture_permission", "denied requestCode=$requestCode")
            finishCapture()
            return
        }
        when (requestCode) {
            REQUEST_AUDIO, REQUEST_CAMERA -> requestPermissionsThenProjection()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PROJECTION || !pendingStartAfterProjection) return
        pendingStartAfterProjection = false
        if (resultCode != RESULT_OK || data == null) {
            OmisuStreamTrace.warn(
                "capture_projection_denied",
                "resultCode=$resultCode dataNull=${data == null}",
            )
            finishCapture()
            return
        }
        startStreamWithProjection(resultCode, data)
    }

    override fun onDestroy() {
        ExternalPlaySessionHelper.isMenuVisible = false
        super.onDestroy()
    }

    companion object {
        private const val EXTRA_GAME_TITLE = "game_title"
        private const val REQUEST_AUDIO = 0xE011
        private const val REQUEST_CAMERA = 0xE012
        private const val REQUEST_PROJECTION = 0xE013
        private const val LAUNCH_DELAY_MS = 2500L
        /** Wait for capture overlay to finish and game task to resume before first video frame. */
        private const val BIND_DELAY_MS = 800L

        private val mainHandler = Handler(Looper.getMainLooper())
        @Volatile
        private var pendingLaunchRunnable: Runnable? = null

        fun scheduleAfterGameLaunch(context: Context, gameTitle: String) {
            cancelPendingLaunch()
            OmisuStreamTrace.event(
                "capture_scheduled",
                "delayMs=$LAUNCH_DELAY_MS game=$gameTitle " +
                    "pkg=${ExternalPlaySessionHelper.gamePackageName}",
            )
            val app = context.applicationContext
            val runnable =
                Runnable {
                    pendingLaunchRunnable = null
                    if (!ExternalPlaySessionHelper.isActive) {
                        OmisuStreamTrace.warn("capture_scheduled", "session inactive — skip launch")
                        return@Runnable
                    }
                    val intent =
                        Intent(app, ExternalPlayStreamCaptureActivity::class.java).apply {
                            addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                    Intent.FLAG_ACTIVITY_NO_ANIMATION,
                            )
                            putExtra(EXTRA_GAME_TITLE, gameTitle)
                        }
                    app.startActivity(intent)
                }
            pendingLaunchRunnable = runnable
            mainHandler.postDelayed(runnable, LAUNCH_DELAY_MS)
        }

        fun cancelPendingLaunch() {
            if (pendingLaunchRunnable != null) {
                OmisuStreamTrace.event("capture_schedule_cancelled")
            }
            pendingLaunchRunnable?.let { mainHandler.removeCallbacks(it) }
            pendingLaunchRunnable = null
        }
    }
}
