package com.omisu.embedded

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class EmbeddedRetroViewFactory(
    private val controller: EmbeddedEmulatorController,
    private val activityProvider: () -> Activity?,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val activity =
            activityProvider()
                ?: throw IllegalStateException(
                    "Embedded play requires a foreground Activity",
                )
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any>
        return EmbeddedRetroPlatformView(activity, controller, params)
    }
}
