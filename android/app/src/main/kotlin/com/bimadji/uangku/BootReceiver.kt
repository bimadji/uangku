package com.bimadji.uangku

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Setelah reboot, hidupkan keep-alive service agar listener pulih
 * tanpa menunggu pengguna membuka aplikasi.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        UangkuKeepAliveService.start(context)
    }
}
