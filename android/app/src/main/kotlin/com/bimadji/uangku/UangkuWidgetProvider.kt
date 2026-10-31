package com.bimadji.uangku

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget home screen 4x1 (DBD §7): pengeluaran hari ini + tombol "+" untuk
 * membuka QuickCashSheet. Data dikirim dari Dart lewat HomeWidget.saveWidgetData.
 */
class UangkuWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val expense = widgetData.getString(KEY_EXPENSE, null) ?: "Rp 0"
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.uangku_widget).apply {
                setTextViewText(R.id.widget_expense, expense)

                // Tombol "+" → buka app langsung ke QuickCashSheet
                setOnClickPendingIntent(
                    R.id.widget_add,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("uangku://quick-cash"),
                    ),
                )

                // Area lain → buka app
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        const val KEY_EXPENSE = "uangku_expense_today"
        const val PROVIDER_NAME = "UangkuWidgetProvider"
    }
}
