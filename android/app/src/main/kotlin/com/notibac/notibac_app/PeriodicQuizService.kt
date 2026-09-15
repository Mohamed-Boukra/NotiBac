package com.notibac.notibac_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import org.json.JSONArray

/**
 * Persistent foreground service that shows a quiz popup every INTERVAL_MS.
 * Structured identically to QuizSchedulerService (which is confirmed working).
 */
class PeriodicQuizService : Service() {

    companion object {
        const val INTERVAL_MS    = 2 * 60 * 1000L   // 2 min for testing
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
        // Show persistent notification immediately — keeps Android from killing us
        startForeground(
            NOTIF_ID,
            NotificationCompat.Builder(this, CH_ID)
                .setContentTitle("NotiBac نشط")
                .setContentText("✅ ستظهر نافذة اختبار كل 2 دقائق (تجريبي)")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        )

        // Cancel any pending loops to avoid duplicates, then start fresh
        handler.removeCallbacks(loop)
        // Fire first popup immediately so user can confirm service works,
        // then every INTERVAL_MS after that
        handler.post(loop)

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
        // Re-schedule FIRST so even if display fails, next tick is queued
        handler.postDelayed(loop, INTERVAL_MS)
        showQuiz()
    }

    // ── Event picking ────────────────────────────────────────────────────────

    private fun pickEvent(): Pair<String, String> {
        return try {
            val prefs      = getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
            val listsJson  = prefs.getString("flutter.event_lists", "[]") ?: "[]"
            val eventsJson = prefs.getString("flutter.events",      "[]") ?: "[]"

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

    // ── Overlay display (identical pattern to QuizSchedulerService) ──────────

    private fun showQuiz() {
        val (date, title) = pickEvent()
        dismiss()
        val params = makeParams()
        val card = dateCard(date, title, params)
        attach(card, params)
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
        ).apply { gravity = Gravity.CENTER }
    }

    private fun dateCard(date: String, title: String, params: WindowManager.LayoutParams): LinearLayout =
        card(Color.WHITE, Color.parseColor("#FF9800")) {
            label("📅  NotiBac Quiz", Color.parseColor("#FF9800"))
            big(date, Color.parseColor("#E65100"))
            hint("اضغط لمعرفة الحدث", Color.GRAY)
            setOnClickListener {
                dismiss()
                val ev = eventCard(title)
                ev.setOnClickListener { dismiss() }
                attach(ev, params)
            }
        }

    private fun eventCard(title: String): LinearLayout =
        card(Color.parseColor("#FFF8E1"), Color.parseColor("#4CAF50")) {
            label("✅  الحدث التاريخي", Color.parseColor("#2E7D32"))
            big(title, Color.parseColor("#1B5E20"))
            hint("اضغط للإغلاق  ✕", Color.parseColor("#C62828"))
        }

    // ── DSL helpers (identical to QuizSchedulerService) ──────────────────────

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    private fun card(fill: Int, stroke: Int, build: LinearLayout.() -> Unit): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(28), dp(20), dp(28), dp(20))
            elevation = dp(8).toFloat()
            background = android.graphics.drawable.GradientDrawable().apply {
                shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                cornerRadius = dp(18).toFloat()
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
            this.text = text; textSize = 28f; setTextColor(color)
            setTypeface(typeface, Typeface.BOLD); gravity = Gravity.CENTER
            setPadding(0, dp(10), 0, dp(8))
        })

    private fun LinearLayout.hint(text: String, color: Int) =
        addView(TextView(context).apply {
            this.text = text; textSize = 12f; setTextColor(color); gravity = Gravity.CENTER
        })

    // ── WindowManager helpers ─────────────────────────────────────────────────

    private fun attach(v: View, p: WindowManager.LayoutParams) {
        currentView = v
        try { wm.addView(v, p) } catch (_: Exception) { currentView = null }
    }

    private fun dismiss() {
        currentView?.let { try { wm.removeView(it) } catch (_: Exception) {} }
        currentView = null
    }
}
