package com.omisu.streaming

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.github.thibaultbee.streampack.core.streamers.utils.MediaProjectionUtils

class StreamingPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var pendingStartConfig: StreamStartConfig? = null
    private var pendingStartResult: MethodChannel.Result? = null
    private var pendingFaceCam: Boolean = false
    private var pendingNeedsMic: Boolean = true

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel =
            MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL).also {
                it.setMethodCallHandler(this)
            }
        eventChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL).also {
                it.setStreamHandler(
                    object : EventChannel.StreamHandler {
                        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                            eventSink = events
                            emitState(StreamingController.state, StreamingController.lastError)
                        }

                        override fun onCancel(arguments: Any?) {
                            eventSink = null
                        }
                    },
                )
            }

        StreamingController.stateListener = { state, message ->
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                emitState(state, message)
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        StreamingController.stateListener = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isStreaming" -> result.success(StreamingController.isStreaming())
            "getStatus" -> {
                result.success(
                    mapOf(
                        "state" to StreamingController.state.name.lowercase(),
                        "message" to StreamingController.lastError,
                    ),
                )
            }
            "stopStream" -> {
                StreamingController.stopStream { ok ->
                    if (ok) {
                        result.success(true)
                    } else {
                        result.error("stop_failed", "Failed to stop stream", null)
                    }
                }
            }
            "startStream" -> {
                val ctx = activity
                if (ctx == null) {
                    result.error("no_activity", "Activity not attached", null)
                    return
                }
                val rtmpUrl = call.argument<String>("rtmpUrl")
                if (rtmpUrl.isNullOrBlank()) {
                    result.error("invalid_args", "rtmpUrl is required", null)
                    return
                }
                val width = call.argument<Int>("width") ?: 1280
                val height = call.argument<Int>("height") ?: 720
                val bitrateKbps = call.argument<Int>("bitrateKbps") ?: 2500
                val fps = call.argument<Int>("fps") ?: 30
                val audioMode =
                    StreamAudioMode.fromWire(call.argument<String>("audioMode"))
                pendingFaceCam = call.argument<Boolean>("faceCamEnabled") ?: false
                // All modes use AudioRecord (mic, playback capture, or both). Android
                // requires RECORD_AUDIO even for MediaProjection game-audio capture.
                pendingNeedsMic = true

                pendingStartConfig =
                    StreamStartConfig(
                        rtmpUrl = rtmpUrl,
                        width = width,
                        height = height,
                        bitrateKbps = bitrateKbps,
                        fps = fps,
                        audioMode = audioMode,
                        faceCamEnabled = pendingFaceCam,
                        faceCamCorner = call.argument<String>("faceCamCorner") ?: "bottomRight",
                        faceCamSize = call.argument<String>("faceCamSize") ?: "medium",
                    )
                pendingStartResult = result
                requestAudioThenProjection()
            }
            else -> result.notImplemented()
        }
    }

    private fun requestAudioThenProjection() {
        val act = activity ?: run {
            failPendingStart("Activity not attached")
            return
        }
        if (!pendingNeedsMic) {
            requestNotificationPermissionIfNeeded()
            return
        }
        val needsAudio =
            ContextCompat.checkSelfPermission(act, Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
        if (needsAudio) {
            ActivityCompat.requestPermissions(
                act,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                REQUEST_AUDIO,
            )
        } else {
            onAudioPermissionReady()
        }
    }

    private fun onAudioPermissionReady() {
        val act = activity ?: run {
            failPendingStart("Activity not attached")
            return
        }
        if (pendingNeedsMic &&
            ContextCompat.checkSelfPermission(act, Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            failPendingStart("Microphone permission is required to capture game audio for streaming")
            return
        }
        requestNotificationPermissionIfNeeded()
    }

    private fun requestNotificationPermissionIfNeeded() {
        val act = activity ?: run {
            failPendingStart("Activity not attached")
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val needsNotification =
                ContextCompat.checkSelfPermission(act, Manifest.permission.POST_NOTIFICATIONS) !=
                    PackageManager.PERMISSION_GRANTED
            if (needsNotification) {
                ActivityCompat.requestPermissions(
                    act,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    REQUEST_NOTIFICATION,
                )
                return
            }
        }
        requestCameraPermissionIfNeeded()
    }

    private fun requestCameraPermissionIfNeeded() {
        val act = activity ?: run {
            failPendingStart("Activity not attached")
            return
        }
        if (pendingFaceCam) {
            val needsCamera =
                ContextCompat.checkSelfPermission(act, Manifest.permission.CAMERA) !=
                    PackageManager.PERMISSION_GRANTED
            if (needsCamera) {
                ActivityCompat.requestPermissions(
                    act,
                    arrayOf(Manifest.permission.CAMERA),
                    REQUEST_CAMERA,
                )
                return
            }
        }
        launchMediaProjection()
    }

    private fun launchMediaProjection() {
        val act = activity ?: run {
            failPendingStart("Activity not attached")
            return
        }
        @Suppress("DEPRECATION")
        act.startActivityForResult(
            MediaProjectionUtils.createScreenCaptureIntent(act),
            REQUEST_PROJECTION,
        )
    }

    private fun onProjectionResult(resultCode: Int, data: android.content.Intent?) {
        val config = pendingStartConfig
        val flutterResult = pendingStartResult
        pendingStartConfig = null
        pendingStartResult = null
        pendingFaceCam = false

        val act = activity
        if (config == null || flutterResult == null) {
            return
        }
        if (act == null) {
            flutterResult.error("no_activity", "Activity not attached", null)
            return
        }
        if (resultCode != Activity.RESULT_OK || data == null) {
            flutterResult.error("projection_denied", "Screen capture permission denied", null)
            return
        }

        StreamingController.bindAndStart(
            context = act,
            resultCode = resultCode,
            resultData = data,
            config = config,
            onSuccess = { flutterResult.success(true) },
            onError = { message -> flutterResult.error("stream_failed", message, null) },
        )
    }

    private fun failPendingStart(message: String) {
        pendingStartConfig = null
        pendingStartResult?.error("stream_failed", message, null)
        pendingStartResult = null
        pendingFaceCam = false
    }

    private fun emitState(state: StreamingState, message: String?) {
        val sink = eventSink ?: return
        sink.success(
            mapOf(
                "type" to "state",
                "state" to state.name.lowercase(),
                "message" to message,
            ),
        )
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        activity = activityPluginBinding.activity
        activityBinding = activityPluginBinding
        activityPluginBinding.addRequestPermissionsResultListener(this)
        activityPluginBinding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        onAttachedToActivity(activityPluginBinding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        return when (requestCode) {
            REQUEST_AUDIO -> {
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
                ) {
                    onAudioPermissionReady()
                } else {
                    failPendingStart("Microphone permission is required to capture game audio for streaming")
                }
                true
            }
            REQUEST_CAMERA -> {
                val act = activity
                if (pendingFaceCam && act != null &&
                    ContextCompat.checkSelfPermission(act, Manifest.permission.CAMERA) !=
                        PackageManager.PERMISSION_GRANTED
                ) {
                    failPendingStart("Camera permission is required for face cam")
                } else {
                    launchMediaProjection()
                }
                true
            }
            REQUEST_NOTIFICATION -> {
                requestCameraPermissionIfNeeded()
                true
            }
            else -> false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?): Boolean {
        if (requestCode != REQUEST_PROJECTION) {
            return false
        }
        onProjectionResult(resultCode, data)
        return true
    }

    companion object {
        const val CHANNEL = "com.omisu.launcher/streaming"
        const val EVENT_CHANNEL = "com.omisu.launcher/streaming_events"

        private const val REQUEST_AUDIO = 0x4F01
        private const val REQUEST_CAMERA = 0x4F02
        private const val REQUEST_PROJECTION = 0x4F03
        private const val REQUEST_NOTIFICATION = 0x4F04
    }
}
