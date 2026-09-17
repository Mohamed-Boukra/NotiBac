package com.notibac.notibac_app

import android.app.*
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

class QuizSchedulerService : Service() {

    companion object {
        const val EXTRA_DELAY = "delay_seconds"
        const val EXTRA_DATE  = "date"
        const val EXTRA_TITLE = "title"
        private const val CH_ID   = "notibac_ch"
        private const val NOTIF_ID = 55
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var wm: WindowManager
    private var currentView: View? = null
    private var quizDate  = ""
    private var quizTitle = ""

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CH_ID, "NotiBac Quiz", NotificationManager.IMPORTANCE_LOW)
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(ch)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val delay = (intent?.getIntExtra(EXTRA_DELAY, 30) ?: 30).toLong()
        quizDate  = intent?.getStringExtra(EXTRA_DATE)  ?: ""
        quizTitle = intent?.getStringExtra(EXTRA_TITLE) ?: ""

        // Foreground notification so Android keeps us alive
        startForeground(NOTIF_ID,
            NotificationCompat.Builder(this, CH_ID)
                .setContentTitle("NotiBac")
                .setContentText("⏳ اختبار قادم خلال $delay ثانية...")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        )

        // ⬇ After the delay: remove notification, show overlay
        handler.postDelayed({
            stopForeground(STOP_FOREGROUND_REMOVE)
            showQuiz()
        }, delay * 1000L)

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        dismiss()          // clean up any leftover view
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Overlay display ───────────────────────────────────────────────────────

    /** Show the quiz card (randomly date or event first) */
    private fun showQuiz() {
        dismiss()
        val params = makeParams()

        val showDateFirst = Math.random() < 0.5
        val firstText = if (showDateFirst) quizDate else quizTitle
        val secondText = if (showDateFirst) quizTitle else quizDate
        
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
                    setOnClickListener { close() }
                }
                attach(backCard, params)
            }
        }
        attach(frontCard, params)
    }

    /** Dismiss and stop the service */
    private fun close() {
        dismiss()
        stopSelf()
    }

    // ── View construction ─────────────────────────────────────────────────────

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

    // ── DSL-style helpers ─────────────────────────────────────────────────────

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    private fun card(fill: Int, stroke: Int, build: LinearLayout.() -> Unit): LinearLayout {
        return LinearLayout(this).apply {
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
    }

    private fun LinearLayout.label(text: String, color: Int) {
        addView(TextView(context).apply {
            this.text = text
            textSize = 11f
            setTextColor(color)
            setTypeface(typeface, Typeface.BOLD)
            gravity = Gravity.CENTER
        })
    }

    private fun LinearLayout.big(text: String, color: Int) {
        addView(TextView(context).apply {
            this.text = text
            textSize = 18f
            setTextColor(color)
            setTypeface(typeface, Typeface.BOLD)
            gravity = Gravity.CENTER
        })
    }

    private fun LinearLayout.hint(text: String, color: Int) {
        addView(TextView(context).apply {
            this.text = text
            textSize = 12f
            setTextColor(color)
            gravity = Gravity.CENTER
        })
    }

    // ── WindowManager helpers ─────────────────────────────────────────────────

    private fun attach(v: View, p: WindowManager.LayoutParams) {
        currentView = v
        try { wm.addView(v, p) } catch (e: Exception) { stopSelf() }
    }

    private fun detach(v: View) {
        try { wm.removeView(v) } catch (_: Exception) {}
        if (currentView === v) currentView = null
    }

    private fun dismiss() {
        currentView?.let { detach(it) }
        currentView = null
    }
}
