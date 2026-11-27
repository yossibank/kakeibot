package com.yossibank.kakeibot.featuremodels.shared.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Job
import kotlin.time.Duration.Companion.seconds

class ErrorNotice(
    private val wait: ScreenWait,
) {
    var message: String by mutableStateOf("")
        private set

    var tone: Tone by mutableStateOf(Tone.error)
        private set

    var count: Int by mutableIntStateOf(0)
        private set

    private var timer: Job? = null

    enum class Tone {
        info,
        error,
    }

    fun show(message: String) {
        present(
            message = message,
            tone = Tone.error,
        )
    }

    fun inform(message: String) {
        present(
            message = message,
            tone = Tone.info,
        )
    }

    fun clear() {
        timer?.cancel()
        timer = null
        message = ""
    }

    private fun present(
        message: String,
        tone: Tone,
    ) {
        this.message = message
        this.tone = tone
        count += 1

        val shown = count

        timer?.cancel()

        timer = wait.after(duration) {
            if (count == shown) {
                timer = null
                this.message = ""
            }
        }
    }

    companion object {
        val duration = 6.seconds
    }
}
