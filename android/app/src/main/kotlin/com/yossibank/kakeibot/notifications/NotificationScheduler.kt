package com.yossibank.kakeibot.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.edit
import com.yossibank.kakeibot.core.concepts.notification.PlannedNotification
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

class NotificationScheduler(
    context: Context,
) {
    private val context = context.applicationContext

    private val alarms: AlarmManager
        get() = context.getSystemService(AlarmManager::class.java)

    private val store
        get() = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)

    fun apply(
        plan: List<PlannedNotification>,
        now: Instant = Instant.now(),
        zone: ZoneId = ZoneId.systemDefault(),
    ) {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) {
            return
        }

        val wanted = plan
            .map { PREFIX + it.identifier to it }
            .filter { (_, notification) -> fireTime(notification, zone) > now }
            .toMap()

        val pending = store.getStringSet(KEY_PENDING, emptySet()).orEmpty()

        pending
            .filter { it !in wanted }
            .forEach { identifier ->
                existing(identifier)?.let { alarms.cancel(it) }
            }

        wanted.forEach { (identifier, notification) ->
            alarms.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                fireTime(notification, zone).toEpochMilli(),
                intent(
                    identifier = identifier,
                    notification = notification,
                ),
            )
        }

        store.edit { putStringSet(KEY_PENDING, wanted.keys) }
    }

    private fun fireTime(
        notification: PlannedNotification,
        zone: ZoneId,
    ): Instant = ZonedDateTime
        .of(
            notification.date.year,
            notification.date.month,
            notification.date.day,
            notification.time.hour,
            notification.time.minute,
            0,
            0,
            zone,
        ).toInstant()

    private fun intent(
        identifier: String,
        notification: PlannedNotification,
    ): PendingIntent {
        val intent = Intent(context, NotificationReceiver::class.java)
            .setAction(identifier)
            .putExtra(NotificationReceiver.EXTRA_TITLE, notification.title)
            .putExtra(NotificationReceiver.EXTRA_BODY, notification.body)
            .putExtra(NotificationReceiver.EXTRA_LINK, notification.route.link)

        return PendingIntent.getBroadcast(
            context,
            identifier.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun existing(identifier: String): PendingIntent? {
        val intent = Intent(context, NotificationReceiver::class.java).setAction(identifier)

        return PendingIntent.getBroadcast(
            context,
            identifier.hashCode(),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private companion object {
        const val PREFIX = "kakeibot."
        const val STORE_NAME = "notifications"
        const val KEY_PENDING = "pending"
    }
}
