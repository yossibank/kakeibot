package com.yossibank.kakeibot.features.support

import androidx.compose.runtime.snapshots.Snapshot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext

object ModelWait {
    private const val TIMEOUT_NANOS = 5_000_000_000L
    private const val INTERVAL_MILLIS = 5L

    suspend fun until(condition: () -> Boolean) {
        val deadline = System.nanoTime() + TIMEOUT_NANOS

        while (true) {
            Snapshot.sendApplyNotifications()

            if (condition()) {
                return
            }

            check(System.nanoTime() < deadline) { "待った値にならなかった" }

            withContext(Dispatchers.Default) {
                delay(INTERVAL_MILLIS)
            }
        }
    }
}
