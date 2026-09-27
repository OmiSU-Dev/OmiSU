package com.omisu.externalplay

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.omisu.launcher.R
import com.omisu.streaming.StreamingController

/**
 * Shown while an Android / Play Store game launched from OmiSU is in the foreground.
 * Stream options are set before launch; this notification only helps return to OmiSU
 * or stop an active stream.
 */
class ExternalPlaySessionService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_STOP_STREAM -> {
                StreamingController.stopStream { }
                val title =
                    intent.getStringExtra(EXTRA_TITLE)
                        ?: ExternalPlaySessionHelper.gameTitle
                val notification =
                    buildNotification(title.ifBlank { getString(R.string.external_play_default_title) })
                startForegroundCompat(notification)
                return START_STICKY
            }
        }
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: ExternalPlaySessionHelper.gameTitle
        val notification = buildNotification(title.ifBlank { getString(R.string.external_play_default_title) })
        startForegroundCompat(notification)
        return START_STICKY
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            @Suppress("DEPRECATION")
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(gameTitle: String): Notification {
        ensureChannel()
        val openOmiSU =
            Intent(this, com.omisu.launcher.MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }
        val contentPending =
            PendingIntent.getActivity(
                this,
                1,
                openOmiSU,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        val builder =
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.mipmap.launcher_icon)
                .setContentTitle(getString(R.string.external_play_notification_title, gameTitle))
                .setContentText(getString(R.string.external_play_notification_body))
                .setOngoing(true)
                .setContentIntent(contentPending)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)

        if (StreamingController.isStreaming()) {
            val stopStreamIntent =
                Intent(this, ExternalPlaySessionService::class.java).apply {
                    action = ACTION_STOP_STREAM
                    putExtra(EXTRA_TITLE, gameTitle)
                }
            val stopPending =
                PendingIntent.getService(
                    this,
                    2,
                    stopStreamIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            builder.addAction(
                R.mipmap.launcher_icon,
                getString(R.string.external_play_stop_stream_action),
                stopPending,
            )
        }

        return builder.build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel =
            NotificationChannel(
                CHANNEL_ID,
                getString(R.string.external_play_notification_channel),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = getString(R.string.external_play_notification_channel_desc)
            }
        nm.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "com.omisu.launcher.external_play"
        private const val NOTIFICATION_ID = 0x4F5053
        private const val EXTRA_TITLE = "title"
        const val ACTION_STOP = "com.omisu.externalplay.STOP"
        const val ACTION_STOP_STREAM = "com.omisu.externalplay.STOP_STREAM"

        fun start(context: Context, gameTitle: String) {
            val intent =
                Intent(context, ExternalPlaySessionService::class.java).apply {
                    putExtra(EXTRA_TITLE, gameTitle)
                }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent =
                Intent(context, ExternalPlaySessionService::class.java).apply {
                    action = ACTION_STOP
                }
            context.startService(intent)
        }

        fun refreshNotification(context: Context) {
            if (!ExternalPlaySessionHelper.isActive) return
            val title = ExternalPlaySessionHelper.gameTitle
            val intent =
                Intent(context, ExternalPlaySessionService::class.java).apply {
                    putExtra(EXTRA_TITLE, title)
                }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}
