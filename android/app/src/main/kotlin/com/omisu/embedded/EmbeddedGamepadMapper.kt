package com.omisu.embedded

import android.view.KeyEvent
import android.view.MotionEvent
import com.swordfish.libretrodroid.GLRetroView
import kotlin.math.abs

/**
 * Mirrors LibretroDroid's internal [com.swordfish.libretrodroid.gamepad.GamepadsManager]
 * so embedded play can map Android gamepad keys before sending them to the core.
 */
object EmbeddedGamepadMapper {
    val gamepadKeys =
        setOf(
            KeyEvent.KEYCODE_DPAD_UP,
            KeyEvent.KEYCODE_DPAD_DOWN,
            KeyEvent.KEYCODE_DPAD_RIGHT,
            KeyEvent.KEYCODE_DPAD_LEFT,
            KeyEvent.KEYCODE_DPAD_DOWN_RIGHT,
            KeyEvent.KEYCODE_DPAD_DOWN_LEFT,
            KeyEvent.KEYCODE_DPAD_UP_LEFT,
            KeyEvent.KEYCODE_DPAD_UP_RIGHT,
            KeyEvent.KEYCODE_BUTTON_SELECT,
            KeyEvent.KEYCODE_BUTTON_START,
            KeyEvent.KEYCODE_BUTTON_A,
            KeyEvent.KEYCODE_BUTTON_X,
            KeyEvent.KEYCODE_BUTTON_Y,
            KeyEvent.KEYCODE_BUTTON_B,
            KeyEvent.KEYCODE_BUTTON_L1,
            KeyEvent.KEYCODE_BUTTON_L2,
            KeyEvent.KEYCODE_BUTTON_R1,
            KeyEvent.KEYCODE_BUTTON_R2,
            KeyEvent.KEYCODE_BUTTON_THUMBL,
            KeyEvent.KEYCODE_BUTTON_THUMBR,
        )

    /** RetroPad swaps Android A/B and X/Y compared to Nintendo layout labels. */
    fun mapKeyCode(keyCode: Int): Int =
        when (keyCode) {
            KeyEvent.KEYCODE_BUTTON_B -> KeyEvent.KEYCODE_BUTTON_A
            KeyEvent.KEYCODE_BUTTON_A -> KeyEvent.KEYCODE_BUTTON_B
            KeyEvent.KEYCODE_BUTTON_X -> KeyEvent.KEYCODE_BUTTON_Y
            KeyEvent.KEYCODE_BUTTON_Y -> KeyEvent.KEYCODE_BUTTON_X
            else -> keyCode
        }

    /**
     * Forwards stick and D-pad motion to LibretroDroid.
     *
     * Most 8/16-bit cores only read the D-pad source; Lemuroid merges the physical
     * D-pad hat and left stick so either input works.
     */
    fun sendStickMotions(view: GLRetroView, event: MotionEvent, port: Int) {
        val hatX = event.getAxisValue(MotionEvent.AXIS_HAT_X)
        val hatY = event.getAxisValue(MotionEvent.AXIS_HAT_Y)
        val leftX = event.getAxisValue(MotionEvent.AXIS_X)
        val leftY = event.getAxisValue(MotionEvent.AXIS_Y)

        val xVal = pickStrongerAxis(hatX, leftX)
        val yVal = pickStrongerAxis(hatY, leftY)

        view.sendMotionEvent(GLRetroView.MOTION_SOURCE_DPAD, xVal, yVal, port)
        view.sendMotionEvent(GLRetroView.MOTION_SOURCE_ANALOG_LEFT, xVal, yVal, port)

        val (rightX, rightY) = readRightStick(event)
        view.sendMotionEvent(GLRetroView.MOTION_SOURCE_ANALOG_RIGHT, rightX, rightY, port)
    }

    private fun pickStrongerAxis(a: Float, b: Float): Float =
        if (abs(a) >= abs(b)) a else b

    private fun readRightStick(event: MotionEvent): Pair<Float, Float> {
        var x = event.getAxisValue(MotionEvent.AXIS_Z)
        var y = event.getAxisValue(MotionEvent.AXIS_RZ)
        if (abs(x) < 0.01f && abs(y) < 0.01f) {
            x = event.getAxisValue(MotionEvent.AXIS_RX)
            y = event.getAxisValue(MotionEvent.AXIS_RY)
        }
        return x to y
    }
}
