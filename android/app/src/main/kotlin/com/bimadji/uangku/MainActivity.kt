package com.bimadji.uangku

import android.app.Notification
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val METHOD_CHANNEL = "uangku/platform"
        const val EVENT_CHANNEL = "uangku/notif_events"
        var eventSink: EventChannel.EventSink? = null

        fun sendNotificationEvent(payload: Map<String, Any?>) {
            activityInstance?.runOnUiThread {
                eventSink?.success(payload)
            }
        }

        private var activityInstance: MainActivity? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        activityInstance = this
        requestListenerRebind()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationAccessSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "isListenerEnabled" -> {
                    val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(this)
                    result.success(enabledPackages.contains(packageName))
                }
                "openQuickCashActivity" -> {
                    result.success(true)
                }
                "isBatteryOptimizationIgnored" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                "requestPostNotificationsPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                                PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            requestPermissions(
                                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                                9001
                            )
                        }
                        result.success(granted)
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun requestListenerRebind() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val component = android.content.ComponentName(this, UangkuNotificationListener::class.java)
                NotificationListenerService.requestRebind(component)
            } catch (_: Exception) {
                // Abaikan bila OS menolak
            }
        }
    }

    override fun onDestroy() {
        activityInstance = null
        eventSink = null
        super.onDestroy()
    }
}

class UangkuNotificationListener : NotificationListenerService() {
    companion object {
        val WHITELIST = setOf(
            "id.co.btn.mobilebanking.android",
            "com.gojek.gopay"
        )
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val pkg = sbn.packageName ?: return
        if (!WHITELIST.contains(pkg)) return

        val extras = sbn.notification?.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: ""

        val payload = mapOf(
            "package_name" to pkg,
            "title" to title,
            "text" to text,
            "post_time" to sbn.postTime,
            "key" to sbn.key
        )

        MainActivity.sendNotificationEvent(payload)
    }
}
