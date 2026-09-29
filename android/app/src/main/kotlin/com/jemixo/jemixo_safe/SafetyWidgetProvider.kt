package com.jemixo.jemixo_safe

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home-screen widget showing the last safety check. Dart writes the values
 * through [update]; the widget itself never scans anything.
 */
class SafetyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) render(context, manager, id)
    }

    companion object {
        private const val PREFS = "jemixo_widget"

        fun update(context: Context, score: Int?, status: String, subtitle: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putInt("score", score ?: -1)
                .putString("status", status)
                .putString("subtitle", subtitle)
                .apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, SafetyWidgetProvider::class.java))
            for (id in ids) render(context, manager, id)
        }

        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val score = prefs.getInt("score", -1)
            val status = prefs.getString("status", null) ?: "Tap to run a safety check"
            val subtitle = prefs.getString("subtitle", null) ?: ""

            val views = RemoteViews(context.packageName, R.layout.widget_safety)
            views.setTextViewText(R.id.widget_status, status)
            views.setTextViewText(R.id.widget_subtitle, subtitle)
            views.setTextViewText(R.id.widget_score, if (score < 0) "—" else score.toString())

            val launch = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            manager.updateAppWidget(id, views)
        }
    }
}
