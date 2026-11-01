package com.bimadji.uangku

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.service.notification.NotificationListenerService

/**
 * Foreground service kecil yang menjaga proses aplikasi tetap hidup agar
 * [UangkuNotificationListener] tidak dilepas MIUI/HyperOS di latar belakang.
 *
 * Keputusan desain (T-037a, mengikuti opsi A yang disetujui pengguna):
 * - Service ini TIDAK memproses notifikasi — hanya memegang prioritas proses.
 * - Listener tetap [UangkuNotificationListener], bridge tetap custom Kotlin
 *   (keputusan T-004 tidak berubah).
 * - START_STICKY: OS yang membunuh service akan menghidupkannya lagi.
 */
class UangkuKeepAliveService : Service() {

    companion object {
        const val CHANNEL_ID = "uangku_service"
        const val NOTIF_ID = 1001

        fun start(context: Context) {
            val intent = Intent(context, UangkuKeepAliveService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Exception) {
                // OS menolak (mis. background start dibatasi) — bukan fatal.
            }
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, UangkuKeepAliveService::class.java))
            } catch (_: Exception) {
                // Abaikan
            }
        }

        fun isRunning(context: Context): Boolean {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE)
                as android.app.ActivityManager
            @Suppress("DEPRECATION")
            return am.getRunningServices(Int.MAX_VALUE)
                .any { it.service.className == UangkuKeepAliveService::class.java.name }
        }

        fun rebindListener(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
            try {
                NotificationListenerService.requestRebind(
                    ComponentName(context, UangkuNotificationListener::class.java)
                )
            } catch (_: Exception) {
                // MIUI bisa mengabaikan; boot receiver + catch-up menutupi celah.
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Uangku aktif")
            .setContentText("Pencatatan otomatis transaksi menyala")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openApp)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }

        // Minta OS mengikat ulang listener begitu service hidup.
        rebindListener(this)
        return START_STICKY
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Layanan pencatatan Uangku",
                NotificationManager.IMPORTANCE_MIN,
            ).apply { description = "Menjaga pencatatan otomatis transaksi tetap berjalan" }
        )
    }
}
