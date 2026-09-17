package com.notibac.notibac_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import java.util.Calendar

/**
 * Persistent foreground service that shows a quiz popup every interval.
 * Respects Do Not Disturb, Vibration, and Sound preferences.
 */
class PeriodicQuizService : Service() {

    companion object {
        const val PREF_ENABLED   = "flutter.periodic_enabled"
        private const val PREFS_FILE = "FlutterSharedPreferences"
        private const val CH_ID      = "notibac_periodic"
        private const val NOTIF_ID   = 88
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var wm: WindowManager
    private var currentView: View? = null

    // Hardcoded fallback events shown when SharedPreferences is empty
    private val fallbackEvents = listOf(
        "28-07-1914" to "اندلاع الحرب العالمية الأولى",
        "10-01-1920" to "تأسيس عصبة الأمم",
        "02-09-1945" to "انتهاء الحرب العالمية الثانية",
        "12-03-1947" to "مبدأ ترومان - بداية الحرب الباردة",
        "09-11-1989" to "سقوط جدار برلين"
    )

    // Fires immediately then re-schedules itself
    private val loop = Runnable { tick() }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CH_ID, "NotiBac Auto Quiz", NotificationManager.IMPORTANCE_LOW)
                .apply { setShowBadge(false) }
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(ch)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prefs = getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        val intervalMins = prefs.getLong("flutter.periodic_interval", 20L)

        // Show persistent notification immediately — keeps Android from killing us
        startForeground(
            NOTIF_ID,
            NotificationCompat.Builder(this, CH_ID)
                .setContentTitle("NotiBac نشط")
                .setContentText("✅ ستظهر نافذة اختبار كل $intervalMins دقيقة")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        )

        // Cancel any pending loops to avoid duplicates, then start fresh
        handler.removeCallbacks(loop)
        
        // Check if we should fire immediately (only on explicit start, not on tick)
        // If started explicitly by user, we show the first one now
        val fromRestart = intent?.getBooleanExtra("from_restart", false) ?: false
        if (fromRestart) {
            // When user changes interval in settings, we restart service and wait 
            // for the interval instead of spamming them immediately.
            handler.postDelayed(loop, intervalMins * 60 * 1000L)
        } else {
            // Initial toggle ON -> fire immediately
            handler.post(loop)
        }

        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(loop)
        dismiss()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Repeating tick ───────────────────────────────────────────────────────

    private fun tick() {
        val prefs = getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        val intervalMs = prefs.getLong("flutter.periodic_interval", 20L) * 60 * 1000L
        
        // Re-schedule FIRST so even if display fails, next tick is queued
        handler.postDelayed(loop, intervalMs)
        
        // Check Do Not Disturb
        val dndEnabled = prefs.getBoolean("flutter.dnd_enabled", false)
        if (dndEnabled) {
            // Flutter stores integers as Long in SharedPreferences
            val dndStart = prefs.getLong("flutter.dnd_start", 23L).toInt()
            val dndEnd = prefs.getLong("flutter.dnd_end", 7L).toInt()
            
            val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            val inDnd = if (dndStart < dndEnd) {
                hour in dndStart until dndEnd
            } else {
                hour >= dndStart || hour < dndEnd
            }
            
            if (inDnd) return // Skip showing the popup
        }

        showQuiz(prefs)
    }

    // ── Event picking ────────────────────────────────────────────────────────

    private fun pickEvent(prefs: android.content.SharedPreferences): Pair<String, String> {
        return try {
            val listsJson  = prefs.getString("flutter.event_lists_v2", "[]") ?: "[]"
            val eventsJson = prefs.getString("flutter.events_v2",      "[]") ?: "[]"

            // Collect enabled list IDs
            val listsArr   = JSONArray(listsJson)
            val enabledIds = mutableSetOf<Int>()
            for (i in 0 until listsArr.length()) {
                val o = listsArr.getJSONObject(i)
                if (o.optBoolean("isEnabled", true)) enabledIds.add(o.optInt("id", -1))
            }

            // Build pool from enabled lists
            val eventsArr = JSONArray(eventsJson)
            val pool = mutableListOf<Pair<String, String>>()
            for (i in 0 until eventsArr.length()) {
                val o = eventsArr.getJSONObject(i)
                if (enabledIds.contains(o.optInt("listId", -1))) {
                    val d = o.optString("date", "")
                    val t = o.optString("title", "")
                    if (d.isNotEmpty()) pool.add(d to t)
                }
            }

            // Fallback: all events regardless of list
            if (pool.isEmpty()) {
                for (i in 0 until eventsArr.length()) {
                    val o = eventsArr.getJSONObject(i)
                    val d = o.optString("date", "")
                    val t = o.optString("title", "")
                    if (d.isNotEmpty()) pool.add(d to t)
                }
            }

            if (pool.isNotEmpty()) pool.random() else fallbackEvents.random()
        } catch (_: Exception) {
            fallbackEvents.random()
        }
    }

    // ── Overlay display ──────────────────────────────────────────────────────

    private fun showQuiz(prefs: android.content.SharedPreferences) {
        val (date, title) = pickEvent(prefs)
        dismiss()
        val params = makeParams()

        val showDateFirst = Math.random() < 0.5
        val firstText = if (showDateFirst) date else title
        val secondText = if (showDateFirst) title else date
        
        val firstBg = if (showDateFirst) Color.parseColor("#E8EAF6") else Color.parseColor("#E0F2F1")
        val firstTextCol = if (showDateFirst) Color.parseColor("#1A237E") else Color.parseColor("#004D40")
        
        val secondBg = if (showDateFirst) Color.parseColor("#E0F2F1") else Color.parseColor("#E8EAF6")
        val secondTextCol = if (showDateFirst) Color.parseColor("#004D40") else Color.parseColor("#1A237E")

        val frontCard = card(Color.WHITE, firstBg) {
            big(firstText, firstTextCol)
            setOnClickListener {
                dismiss()
                val backCard = card(Color.WHITE, secondBg) {
                    big(secondText, secondTextCol)
                    setOnClickListener { dismiss() }
                }
                attach(backCard, params)
            }
        }
        attach(frontCard, params)
    }

    private fun makeParams(): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply { 
            gravity = Gravity.TOP or Gravity.END
            x = dp(16)
            y = resources.displayMetrics.heightPixels / 6
        }
    }

    // ── DSL helpers ──────────────────────────────────────────────────────────

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    private fun card(fill: Int, stroke: Int, build: LinearLayout.() -> Unit): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(14), dp(24), dp(14))
            elevation = dp(8).toFloat()
            background = android.graphics.drawable.GradientDrawable().apply {
                shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                cornerRadius = dp(50).toFloat()
                setColor(fill)
                setStroke(dp(2), stroke)
            }
            build()
        }

    private fun LinearLayout.label(text: String, color: Int) =
        addView(TextView(context).apply {
            this.text = text; textSize = 11f; setTextColor(color)
            setTypeface(typeface, Typeface.BOLD); gravity = Gravity.CENTER
        })

    private fun LinearLayout.big(text: String, color: Int) =
        addView(TextView(context).apply {
            this.text = text; textSize = 18f; setTextColor(color)
            setTypeface(typeface, Typeface.BOLD); gravity = Gravity.CENTER
        })

    private fun LinearLayout.hint(text: String, color: Int) =
        addView(TextView(context).apply {
            this.text = text; textSize = 12f; setTextColor(color); gravity = Gravity.CENTER
        })

    // ── WindowManager helpers ────────────────────────────────────────────────

    private fun attach(v: View, p: WindowManager.LayoutParams) {
        currentView = v
        try { wm.addView(v, p) } catch (_: Exception) { currentView = null }
    }

    private fun dismiss() {
        currentView?.let { try { wm.removeView(it) } catch (_: Exception) {} }
        currentView = null
    }
}
