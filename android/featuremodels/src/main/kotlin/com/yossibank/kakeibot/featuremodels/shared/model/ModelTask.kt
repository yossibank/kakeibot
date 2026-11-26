package com.yossibank.kakeibot.featuremodels.shared.model

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.isStorageFull
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlin.time.Duration

class ModelTask {
    var message: String by mutableStateOf("")
        private set

    var tone: Tone by mutableStateOf(Tone.error)
        private set

    var count: Int by mutableIntStateOf(0)
        private set

    private var running: Int by mutableIntStateOf(0)

    enum class Tone {
        info,
        error,
    }

    val isRunning: Boolean
        get() = running > 0

    fun show(message: String) {
        show(
            message = message,
            tone = Tone.error,
        )
    }

    fun inform(message: String) {
        show(
            message = message,
            tone = Tone.info,
        )
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
            return action()
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            show(if (AppDatabase.isStorageFull(error)) storageFull else describe(error))
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
            show(failure)
        }

        return isFailed
    }

    suspend fun <Value> observe(
        values: Flow<Value>,
        failure: String,
        failing: (Boolean) -> Unit,
        receive: suspend (Value) -> Unit,
    ) {
        failing(false)

        val isFailed = observe(
            values = values,
            failure = failure,
            receive = receive,
        )

        failing(isFailed)
    }

    @Composable
    fun Timer() {
        val shown = count

        LaunchedEffect(shown) {
            if (shown > 0) {
                delay(MILLIS)
                clear()
            }
        }
    }

    private fun show(
        message: String,
        tone: Tone,
    ) {
        this.message = message
        this.tone = tone
        count += 1
    }

    companion object {
        const val MILLIS = 6_000L
        const val saveFailed = "保存できませんでした"
        const val settingSaveFailed = "設定を保存できませんでした"
        const val restoreFailed = "元に戻せませんでした"
        const val loadFailed = "読み込めませんでした"
        const val storageFull = "端末の空き容量が足りません"

        suspend fun <Value : Any> quiet(action: suspend () -> Value): Value? = try {
            action()
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            null
        }
    }
}
