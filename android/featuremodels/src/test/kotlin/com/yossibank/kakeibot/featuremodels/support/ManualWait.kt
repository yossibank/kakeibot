package com.yossibank.kakeibot.featuremodels.support

import com.yossibank.kakeibot.featuremodels.shared.model.ScreenWait
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.time.Duration

class ManualWait {
    val wait = ScreenWait(
        scope = CoroutineScope(Dispatchers.Unconfined),
        sleep = ::sleep,
    )

    private val sleepers = mutableMapOf<Int, Sleeper>()
    private var time = Duration.ZERO
    private var nextId = 0

    val isSleeping: Boolean
        get() = sleepers.isNotEmpty()

    private class Sleeper(
        val deadline: Duration,
        val continuation: CancellableContinuation<Unit>,
    )

    fun advance(by: Duration) {
        time += by

        val woken = sleepers.filterValues { it.deadline <= time }

        woken.keys.forEach(sleepers::remove)
        woken.values.forEach { it.continuation.resume(Unit) }
    }

    private suspend fun sleep(duration: Duration) {
        val id = nextId
        val deadline = time + duration

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
}
