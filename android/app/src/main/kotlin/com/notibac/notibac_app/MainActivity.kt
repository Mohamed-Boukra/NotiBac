package com.notibac.notibac_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "notibac/scheduler"
        const val OVERLAY_PERMISSION_REQ = 1001
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingDelay: Int = 30
    private var pendingDate: String = ""
    private var pendingTitle: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }
                    "requestPermission" -> {
                        if (Settings.canDrawOverlays(this)) {
                            result.success(true)
                        } else {
                            pendingResult = result
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivityForResult(intent, OVERLAY_PERMISSION_REQ)
                        }
                    }
                    "scheduleOverlay" -> {
                        val delaySeconds = call.argument<Int>("delay_seconds") ?: 30
                        val date = call.argument<String>("date") ?: ""
                        val title = call.argument<String>("title") ?: ""

                        if (!Settings.canDrawOverlays(this)) {
                            pendingResult = result
                            pendingDelay = delaySeconds
                            pendingDate = date
                            pendingTitle = title
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivityForResult(intent, OVERLAY_PERMISSION_REQ)
                        } else {
                            startQuizService(delaySeconds, date, title)
                            result.success(true)
                        }
                    }
                    "startPeriodic" -> {
                        // Save enabled flag so START_STICKY restart honours it
                        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                            .edit().putBoolean(PeriodicQuizService.PREF_ENABLED, true).apply()
                        val intent = Intent(this, PeriodicQuizService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "stopPeriodic" -> {
                        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                            .edit().putBoolean(PeriodicQuizService.PREF_ENABLED, false).apply()
                        stopService(Intent(this, PeriodicQuizService::class.java))
                        result.success(true)
                    }
                    "restartPeriodic" -> {
                        val intent = Intent(this, PeriodicQuizService::class.java).apply {
                            putExtra("from_restart", true)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "cancelOverlay" -> {
                        stopService(Intent(this, QuizSchedulerService::class.java))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQ) {
            val granted = Settings.canDrawOverlays(this)
            val pending = pendingResult
            pendingResult = null
            if (granted && pendingDate.isNotEmpty()) {
                startQuizService(pendingDelay, pendingDate, pendingTitle)
                pending?.success(true)
            } else {
                pending?.success(granted)
            }
            pendingDate = ""
            pendingTitle = ""
        }
    }

    private fun startQuizService(delaySeconds: Int, date: String, title: String) {
        val intent = Intent(this, QuizSchedulerService::class.java).apply {
            putExtra(QuizSchedulerService.EXTRA_DELAY, delaySeconds)
            putExtra(QuizSchedulerService.EXTRA_DATE, date)
            putExtra(QuizSchedulerService.EXTRA_TITLE, title)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
