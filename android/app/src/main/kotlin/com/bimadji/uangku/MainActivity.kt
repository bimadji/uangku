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
        private var activityInstance: MainActivity? = null

        fun sendNotificationEvent(payload: Map<String, Any?>) {
            activityInstance?.runOnUiThread {
                eventSink?.success(payload)
            }
        }

        fun sendListenerStatus(connected: Boolean) {
            activityInstance?.runOnUiThread {
                eventSink?.success(
                    mapOf("type" to "listener_status", "connected" to connected)
                )
            }
        }

        /** Diminta ulang dari mana pun (teruncak service). MIUI bisa mengabaikannya. */
        fun requestListenerRebind() {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
            try {
                val ctx = activityInstance?.applicationContext ?: return
                NotificationListenerService.requestRebind(
                    android.content.ComponentName(
                        ctx, UangkuNotificationListener::class.java
                    )
                )
            } catch (_: Exception) {
                // MIUI bisa mengabaikan — status tetap dilaporkan jujur.
            }
        }
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
                "isListenerConnected" -> {
                    result.success(UangkuNotificationListener.isBound)
                }
                "startKeepAlive" -> {
                    UangkuKeepAliveService.start(this)
                    result.success(true)
                }
                "stopKeepAlive" -> {
                    UangkuKeepAliveService.stop(this)
                    result.success(true)
                }
                "isKeepAliveRunning" -> {
                    result.success(UangkuKeepAliveService.isRunning(this))
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

    private fun requestListenerRebind() = Companion.requestListenerRebind()

    override fun onResume() {
        super.onResume()
        // Izin masih terdaftar tapi service sudah di-unbind OS (MIUI agresif).
        requestListenerRebind()
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

        /** Status binding terakhir. Dibaca MethodChannel agar Dart tahu apakah
         * listener benar-benar terhubung, bukan sekadar izin terdaftar. */
        @Volatile
        var isBound: Boolean = false
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isBound = true
        MainActivity.sendListenerStatus(true)
        // Catch-up: notifikasi yang tiba saat service mati masih ada di tray.
        // DedupService menolak yang sudah pernah tercatat, jadi aman.
        try {
            activeNotifications?.forEach { onNotificationPosted(it) }
        } catch (_: Exception) {
            // activeNotifications bisa melempar bila service baru putus
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isBound = false
        MainActivity.sendListenerStatus(false)
        // Coba pulih otomatis; MIUI bisa mengabaikan — status tetap jujur.
        MainActivity.requestListenerRebind()
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
