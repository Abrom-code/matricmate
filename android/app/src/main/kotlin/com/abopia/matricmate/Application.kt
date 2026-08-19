package com.abopia.matricmate

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * Custom Application class that creates the FCM notification channel at the
 * earliest possible point — before any Activity or Service starts.
 *
 * This is critical for background/killed-state FCM delivery:
 *   • When the app is killed and FCM delivers a notification message, Android
 *     runs this Application.onCreate() in the background process BEFORE
 *     showing the notification.
 *   • The channel "matricmate_default" must already exist in
 *     NotificationManager, otherwise Android silently drops the notification.
 *   • Flutter's Dart code (main.dart) only runs when the app is open, so
 *     creating the channel there alone is not sufficient.
 *
 * Channel importance must be HIGH (= heads-up / banner notifications).
 * Downgrading importance after first creation requires the user to do it
 * manually in system settings, so we set it correctly here from the start.
 */
class MatricMateApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createFcmNotificationChannel()
    }

    private fun createFcmNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "matricmate_default",
                "General Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Announcements, payment updates, and new exam alerts"
                enableLights(true)
                enableVibration(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}
