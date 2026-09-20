package com.omisu.streaming

import com.swordfish.libretrodroid.GLRetroView

/**
 * Holds the active [GLRetroView] while embedded play is running.
 * MediaProjection cannot see SurfaceView/GL content on many devices; streaming
 * uses [EmbeddedRetroVideoSource] to PixelCopy this view instead.
 */
object EmbeddedStreamCapture {
    @Volatile
    var captureView: GLRetroView? = null

    fun register(view: GLRetroView) {
        captureView = view
    }

    fun unregister(view: GLRetroView? = null) {
        if (view == null || captureView === view) {
            captureView = null
        }
    }

    fun isActive(): Boolean = captureView != null
}
