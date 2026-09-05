package com.example.eps_topik_app

import android.content.pm.ActivityInfo
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ORIENTATION_CHANNEL = "com.epstopik.app/orientation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ORIENTATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "forceLandscape" -> {
                    requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                    result.success(true)
                }
                "unlockOrientation" -> {
                    requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
