package com.orailnoor.droiddesk.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.orailnoor.droiddesk.MainActivity
import com.orailnoor.droiddesk.runtime.AndroidAppBridge
import com.orailnoor.droiddesk.runtime.ChrootRuntime
import com.orailnoor.droiddesk.runtime.LinuxRuntime

/**
 * Foreground service that keeps the Linux runtime alive.
 *
 * Android aggressively kills background processes (especially Android 12+'s
 * Phantom Process Killer). This service ensures our native Termux/chroot session, desktop
 * environment, and Wayland compositor survive when the user switches apps.
 */
class DroidDeskService : Service() {

    companion object {
        const val CHANNEL_ID = "droiddesk_service"
        const val NOTIFICATION_ID = 1001
        const val ACTION_EXIT = "com.orailnoor.droiddesk.service.ACTION_EXIT"
        const val ACTION_TOGGLE_WAKELOCK = "com.orailnoor.droiddesk.service.ACTION_TOGGLE_WAKELOCK"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var isWakeLockActive = true

    override fun onCreate() {
        super.onCreate()
        AndroidAppBridge.start(this)
        createNotificationChannel()
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_EXIT -> {
                shutdownAndExit()
                return START_NOT_STICKY
            }
            ACTION_TOGGLE_WAKELOCK -> {
                if (isWakeLockActive) {
                    releaseWakeLock()
                    isWakeLockActive = false
                } else {
                    acquireWakeLock()
                    isWakeLockActive = true
                }
                updateNotification(if (isWakeLockActive) "Desktop running (WakeLock active)" else "Desktop running (WakeLock released)")
                return START_STICKY
            }
        }

        val notification = buildNotification(if (isWakeLockActive) "Desktop running (WakeLock active)" else "Desktop running")

        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            notification,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            } else {
                0
            }
        )

        return START_STICKY
    }

    private fun shutdownAndExit() {
        Thread {
            try {
                LinuxRuntime(this).stopSession()
                ChrootRuntime(this).stopSession()
            } catch (_: Throwable) {}
            releaseWakeLock()
            AndroidAppBridge.stop()
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
            stopSelf()
        }.start()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        AndroidAppBridge.stop()
        releaseWakeLock()
        super.onDestroy()
    }

    // ── Notification ──

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "DroidDesk Linux Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the Linux desktop environment running"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(contentText: String): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val exitIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, DroidDeskService::class.java).apply { action = ACTION_EXIT },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val wakeLockIntent = PendingIntent.getService(
            this,
            2,
            Intent(this, DroidDeskService::class.java).apply { action = ACTION_TOGGLE_WAKELOCK },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DroidDesk")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(
                android.R.drawable.ic_lock_idle_charging,
                if (isWakeLockActive) "Release WakeLock" else "Acquire WakeLock",
                wakeLockIntent
            )
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Exit",
                exitIntent
            )
            .build()
    }

    fun updateNotification(text: String) {
        val notification = buildNotification(text)
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    // ── Wake Lock ──

    private fun acquireWakeLock() {
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        if (wakeLock == null) {
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "DroidDesk::LinuxRuntime"
            )
        }
        wakeLock?.let {
            if (!it.isHeld) {
                it.acquire(Long.MAX_VALUE) // Keep CPU alive
            }
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }
}
