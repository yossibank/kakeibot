package com.yossibank.kakeibot.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.yossibank.kakeibot.appfeature.app.AppModel
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.file
import com.yossibank.kakeibot.store.queries.methods.notificationInput
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Instant

class NotificationBootReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) {
            return
        }

        val result = goAsync()
        val app = context.applicationContext

        CoroutineScope(Dispatchers.IO).launch {
            var database: AppDatabase? = null

            try {
                val opened = AppDatabase.file(app, now = Instant.now())

                database = opened

                val today = AppModel.deviceDay()
                val plan = opened.notificationInput(from = today).plan(today = today)

                NotificationScheduler(app).apply(plan, now = Instant.now())
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                return@launch
            } finally {
                database?.close()
                result.finish()
            }
        }
    }
}
