package com.yossibank.kakeibot.featuremodels.support

import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine
import java.time.Instant
import kotlin.coroutines.resume

class FakeVoiceClock {
    val screenClock = ScreenClock { time }

    private val sleepers = mutableMapOf<Int, Sleeper>()
    private var time: Instant = ModelTestDatabase.now
    private var nextId = 0

    val isSleeping: Boolean
        get() = sleepers.isNotEmpty()

    private class Sleeper(
        val deadline: Instant,
        val continuation: CancellableContinuation<Unit>,
    )

    suspend fun sleep(millis: Long) {
        val id = nextId
        val deadline = time.plusMillis(millis)

        nextId += 1

        suspendCancellableCoroutine { continuation ->
            sleepers[id] = Sleeper(
                deadline = deadline,
                continuation = continuation,
            )

            continuation.invokeOnCancellation {
                sleepers.remove(id)
            }
        }
    }

    fun advance(millis: Long) {
        time = time.plusMillis(millis)

        val woken = sleepers.filterValues { it.deadline <= time }

        woken.keys.forEach(sleepers::remove)
        woken.values.forEach { it.continuation.resume(Unit) }
    }
}
