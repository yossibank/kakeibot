package com.yossibank.kakeibot.featuremodels.shared.model

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.retryWhen
import kotlinx.coroutines.flow.shareIn
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

object ScreenObservation {
    val retryDelays: List<Duration> = listOf(1.seconds, 2.seconds, 4.seconds)

    suspend fun <Value> retry(
        values: Flow<Value>,
        retryDelays: List<Duration> = ScreenObservation.retryDelays,
        receive: suspend (Value) -> Unit,
    ): Boolean {
        var attempt = 0

        while (true) {
            try {
                values.collect { receive(it) }
                return false
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                if (attempt >= retryDelays.size) {
                    return true
                }

                delay(retryDelays[attempt])
                attempt += 1
            }
        }
    }

    fun <Value> share(
        values: Flow<Value>,
        scope: CoroutineScope,
        started: SharingStarted,
        retryDelay: Duration = retryDelays.first(),
    ): Flow<Value> = values
        .map { Result.success(it) }
        .retryWhen { cause, _ ->
            emit(Result.failure(cause))
            delay(retryDelay)
            true
        }.shareIn(
            scope = scope,
            started = started,
            replay = 1,
        ).map { it.getOrThrow() }
}
