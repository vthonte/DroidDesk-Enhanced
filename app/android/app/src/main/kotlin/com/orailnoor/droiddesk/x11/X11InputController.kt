package com.orailnoor.droiddesk.x11

import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import com.termux.x11.LorieView
import com.termux.x11.MainActivity
import com.termux.x11.input.InputEventSender
import com.termux.x11.input.TouchInputHandler

/** Connects LorieView to the gesture/input implementation imported from Termux:X11. */
class X11InputController(private val lorieView: LorieView) {
    private val inputHandler = TouchInputHandler(
        MainActivity.getInstance(),
        InputEventSender(lorieView),
    )

    private val scaleGestureDetector = ScaleGestureDetector(
        lorieView.context,
        object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScale(detector: ScaleGestureDetector): Boolean {
                val factor = detector.scaleFactor
                if (factor > 1.04f) {
                    lorieView.adjustRendererZoom(8)
                    return true
                } else if (factor < 0.96f) {
                    lorieView.adjustRendererZoom(-8)
                    return true
                }
                return false
            }
        }
    )

    var mode: Int = TouchInputHandler.InputMode.TRACKPAD
        private set

    var scalePercent: Int = DEFAULT_SCALE_PERCENT
        private set

    init {
        setMode(mode)
        MainActivity.getInstance().setKeyHandler(inputHandler::sendKeyEvent)
        lorieView.setCallback { width, height, transform ->
            inputHandler.handleInputTransformChanged(width, height, transform)
        }
        lorieView.setOnTouchListener(::handleMotionEvent)
        lorieView.setOnGenericMotionListener(::handleMotionEvent)
    }

    fun nextMode(): Int {
        val next = when (mode) {
            TouchInputHandler.InputMode.TRACKPAD -> TouchInputHandler.InputMode.SIMULATED_TOUCH
            TouchInputHandler.InputMode.SIMULATED_TOUCH -> TouchInputHandler.InputMode.TOUCH
            else -> TouchInputHandler.InputMode.TRACKPAD
        }
        setMode(next)
        return next
    }

    fun modeLabel(): String = when (mode) {
        TouchInputHandler.InputMode.SIMULATED_TOUCH -> "Touchscreen"
        TouchInputHandler.InputMode.TOUCH -> "Direct touch"
        else -> "Trackpad"
    }

    fun cycleScale(): Int {
        scalePercent = when (scalePercent) {
            100 -> 125
            125 -> 150
            150 -> 200
            else -> 100
        }
        applyScale(scalePercent)
        return scalePercent
    }

    private fun applyScale(scale: Int) {
        val prefs = MainActivity.getPrefs()
        if (scale == 100) {
            prefs.displayResolutionMode.put("native")
            prefs.displayScale.put(100)
        } else {
            prefs.displayResolutionMode.put("scaled")
            prefs.displayScale.put(scale)
        }
        prefs.adjustResolution.put(true)
        lorieView.reloadPreferences(prefs)
        lorieView.triggerCallback()
    }

    fun dispose() {
        MainActivity.getInstance().setKeyHandler(null)
        lorieView.setOnTouchListener(null)
        lorieView.setOnGenericMotionListener(null)
        lorieView.setCallback(null)
    }

    private fun setMode(newMode: Int) {
        mode = newMode
        val prefs = MainActivity.getPrefs()
        prefs.touchMode.put(newMode.toString())
        inputHandler.reloadPreferences(prefs)
    }

    private fun handleMotionEvent(view: View, event: MotionEvent): Boolean {
        if (event.pointerCount >= 2) {
            scaleGestureDetector.onTouchEvent(event)
            if (scaleGestureDetector.isInProgress) {
                return true
            }
        }
        return inputHandler.handleTouchEvent(lorieView, view, event)
    }

    companion object {
        const val DEFAULT_SCALE_PERCENT = 100

        /** Must run before LorieView is measured so Xwayland starts at the scaled resolution. */
        fun configureDisplayScale(scale: Int = DEFAULT_SCALE_PERCENT) {
            MainActivity.getPrefs().apply {
                if (scale == 100) {
                    displayResolutionMode.put("native")
                    displayScale.put(100)
                } else {
                    displayResolutionMode.put("scaled")
                    displayScale.put(scale)
                }
                displayStretch.put(true)
                scaleTouchpad.put(true)
                adjustResolution.put(true)
            }
        }
    }
}
