package com.yossibank.kakeibot.features.shared.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CancellationException

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
        failure: String? = null,
        action: suspend () -> Value,
    ): Value? {
        running += 1

        try {
            val value = action()
            message = ""

            return value
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            if (failure != null) {
                message = failure
            }

            return null
        } finally {
            running -= 1
        }
    }

    companion object {
        const val saveFailed = "保存できませんでした"
        const val restoreFailed = "元に戻せませんでした"

        suspend fun <Value : Any> quiet(action: suspend () -> Value): Value? = try {
            action()
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            null
        }
    }
}
