package com.yossibank.kakeibot.featuremodels.shared.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlin.time.Duration

class ModelTask {
    var message: String by mutableStateOf("")
        private set

    private var running: Int by mutableIntStateOf(0)

    val isRunning: Boolean
        get() = running > 0

    fun show(message: String) {
        this.message = message
    }

    fun clear() {
        message = ""
    }

    suspend fun <Value : Any> attempt(
        failure: String,
        action: suspend () -> Value,
    ): Value? = attempt(
        describe = { failure },
        action = action,
    )

    suspend fun <Value : Any> attempt(
        describe: (Exception) -> String,
        action: suspend () -> Value,
    ): Value? {
        running += 1

        try {
            val value = action()
            message = ""

            return value
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            message = describe(error)
            return null
        } finally {
            running -= 1
        }
    }

    suspend fun <Value> observe(
        values: Flow<Value>,
        failure: String,
        retryDelays: List<Duration> = ScreenObservation.retryDelays,
        receive: suspend (Value) -> Unit,
    ): Boolean {
        val isFailed = ScreenObservation.retry(
            values = values,
            retryDelays = retryDelays,
            receive = receive,
        )

        if (isFailed) {
            message = failure
        }

        return isFailed
    }

    companion object {
        const val saveFailed = "保存できませんでした"
        const val restoreFailed = "元に戻せませんでした"
        const val loadFailed = "読み込めませんでした"

        suspend fun <Value : Any> quiet(action: suspend () -> Value): Value? = try {
            action()
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            null
        }
    }
}
