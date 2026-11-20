package com.yossibank.kakeibot.notifications

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.appfeature.app.MainActivity

class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        val isAllowed = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED

        if (!isAllowed &&
            android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU
        ) {
            return
        }

        val identifier = intent.action ?: return
        val link = intent.getStringExtra(EXTRA_LINK)

        createChannel(context)

        val open = Intent(context, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra(MainActivity.EXTRA_LINK, link)

        val tap = PendingIntent.getActivity(
            context,
            identifier.hashCode(),
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat
            .Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_bell)
            .setContentTitle(intent.getStringExtra(EXTRA_TITLE))
            .setContentText(intent.getStringExtra(EXTRA_BODY))
            .setStyle(NotificationCompat.BigTextStyle().bigText(intent.getStringExtra(EXTRA_BODY)))
            .setContentIntent(tap)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(identifier.hashCode(), notification)
    }

    companion object {
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_LINK = "link"

        private const val CHANNEL_ID = "reminders"

        private fun createChannel(context: Context) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "記録と固定費のお知らせ",
                NotificationManager.IMPORTANCE_DEFAULT,
            )

            context.getSystemService(
                NotificationManager::class.java,
            ).createNotificationChannel(channel)
        }
    }
}
