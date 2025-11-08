package com.hartvig_solutions.tread_runner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val channelName = "com.hartvig_solutions.tread_runner/health"
    private val coroutineScope = MainScope()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAuthorization" -> {
                    coroutineScope.launch {
                        // TODO: Request Google Fit permissions.
                        result.success(false)
                    }
                }
                "writeWorkout" -> {
                    coroutineScope.launch {
                        // TODO: Write workout session to Google Fit.
                        result.success(false)
                    }
                }
                "readLatestHeartRate" -> {
                    coroutineScope.launch {
                        // TODO: Read heart rate from Google Fit.
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
