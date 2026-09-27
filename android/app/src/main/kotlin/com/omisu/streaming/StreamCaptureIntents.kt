package com.omisu.streaming

import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import io.github.thibaultbee.streampack.core.streamers.utils.MediaProjectionUtils

/**
 * Builds the screen-capture consent intent. External Play Store games need
 * full-display capture so the stream follows the game after launch (single-app
 * pick before the game is running often yields a black feed).
 */
object StreamCaptureIntents {
    fun createScreenCaptureIntent(
        context: Context,
        preferFullDisplay: Boolean,
    ): Intent {
        if (preferFullDisplay && Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val mgr =
                context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val config =
                android.media.projection.MediaProjectionConfig.createConfigForDefaultDisplay()
            return mgr.createScreenCaptureIntent(config)
        }
        return MediaProjectionUtils.createScreenCaptureIntent(context)
    }
}
