package com.yossibank.kakeibot.features.screens.entry.voice

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.voice.VoiceReading
import com.yossibank.kakeibot.designsystem.components.modal.UndoNoticeState
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.model.VoiceUndo
import com.yossibank.kakeibot.features.screens.entry.model.apply
import com.yossibank.kakeibot.features.screens.entry.model.undo
import com.yossibank.kakeibot.features.screens.entry.model.voiceHints
import com.yossibank.kakeibot.features.screens.entry.model.voiceReading
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceResult.Outcome
import com.yossibank.kakeibot.features.shared.model.ScreenClock
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class EntryVoiceFlow(
    context: Context,
    scope: CoroutineScope,
    clock: ScreenClock,
) {
    val state = State()
    val input = Input(isAvailable = EntryVoiceSpeech.isAvailable(context))
    val output = Output(state)

    private val dependencies = Dependencies(context, scope, clock)
    private val runtime = Runtime()

    sealed interface Phase {
        data object Idle : Phase

        data object Denied : Phase

        data class Listening(
            val transcript: String = "",
            val preview: VoiceReading? = null,
            val levels: List<Float> = quietLevels,
            val silenceStart: Long? = null,
            val hasVoice: Boolean = false,
        ) : Phase

        data class Reading(
            val transcript: String,
        ) : Phase
    }

    class State {
        var phase: Phase by mutableStateOf(Phase.Idle)
            private set

        var notice: EntryVoiceResult? by mutableStateOf(null)
            private set

        var startCount: Int by mutableStateOf(0)
            private set

        var endCount: Int by mutableStateOf(0)
            private set

        var undo: VoiceUndo? = null
            private set

        fun start() {
            phase = Phase.Listening()
            startCount += 1
        }

        fun finish(transcript: String) {
            phase = Phase.Reading(transcript = transcript)
            endCount += 1
        }

        fun countEnd() {
            endCount += 1
        }

        fun move(to: Phase) {
            phase = to
        }

        fun show(notice: EntryVoiceResult) {
            this.notice = notice
        }

        fun remember(undo: VoiceUndo) {
            this.undo = undo
        }

        fun clearNotice() {
            notice = null
            undo = null
        }
    }

    class Input(
        val isAvailable: Boolean,
    ) {
        val silenceMillis: Long = SILENCE_MILLIS
    }

    class Output(
        private val state: State,
    ) {
        val isActive: Boolean
            get() = state.phase != Phase.Idle

        val listening: Phase.Listening?
            get() = state.phase as? Phase.Listening
    }

    private class Dependencies(
        val context: Context,
        val scope: CoroutineScope,
        val clock: ScreenClock,
    )

    private class Runtime {
        var recognizer: SpeechRecognizer? = null
        var session: Session? = null
        var noticeJob: Job? = null
        var silenceJob: Job? = null
    }

    private data class Session(
        val model: EntryModel,
        val today: LocalDate,
    )

    fun start(
        model: EntryModel,
        today: LocalDate,
    ) {
        if (output.isActive || !input.isAvailable ||
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S
        ) {
            return
        }

        clearNotice()
        model.state.focus(EntryModel.Field.Amount)

        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(dependencies.context)

        runtime.recognizer = recognizer
        runtime.session = Session(model = model, today = today)
        state.start()

        recognizer.setRecognitionListener(Listener())
        recognizer.startListening(EntryVoiceSpeech.intent(hints = model.output.voiceHints))
    }

    fun deny() {
        state.move(to = Phase.Denied)
    }

    fun finish() {
        val listening = output.listening ?: return

        runtime.silenceJob?.cancel()
        state.finish(transcript = listening.transcript)
        runtime.recognizer?.stopListening()
    }

    fun cancel() {
        if (state.phase == Phase.Denied) {
            state.move(to = Phase.Idle)
            return
        }

        if (state.phase is Phase.Listening) {
            state.countEnd()
        }

        runtime.recognizer?.cancel()
        reset()
    }

    fun undoLast(model: EntryModel) {
        state.undo?.let(model.state::undo)
        clearNotice()
    }

    fun clearNotice() {
        runtime.noticeJob?.cancel()
        state.clearNotice()
    }

    fun close() {
        runtime.recognizer?.cancel()
        reset()
        clearNotice()
    }

    fun silencePassed(since: Long): Long =
        (dependencies.clock.now.toEpochMilli() - since).coerceIn(0L, input.silenceMillis)

    private fun read(
        candidates: List<String>,
        session: Session,
    ) {
        val model = session.model

        val text = EntryVoiceSpeech.text(candidates = candidates) {
            model.output.voiceReading(text = it, today = session.today).amount != null
        }

        if (text.isEmpty()) {
            show(EntryVoiceResult(outcome = Outcome.Unheard, count = 0, text = ""))
            return
        }

        val reading = model.output.voiceReading(text = text, today = session.today)

        if (reading.isEmpty) {
            show(EntryVoiceResult(outcome = Outcome.Unheard, count = 0, text = text))
            return
        }

        val undo = model.apply(reading)

        if (reading.amount == null) {
            show(
                EntryVoiceResult(
                    outcome = Outcome.MissingAmount,
                    count = reading.count,
                    text = text,
                ),
            )
            return
        }

        show(EntryVoiceResult(outcome = Outcome.Applied, count = reading.count, text = text))
        state.remember(undo)
    }

    private fun download(): Outcome {
        val recognizer = runtime.recognizer

        if (recognizer == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return Outcome.Unsupported
        }

        recognizer.triggerModelDownload(EntryVoiceSpeech.intent(hints = emptyList()))

        return Outcome.Downloading
    }

    private fun show(notice: EntryVoiceResult) {
        runtime.noticeJob?.cancel()
        state.show(notice)

        runtime.noticeJob = dependencies.scope.launch {
            delay(UndoNoticeState.MILLIS)

            if (state.notice?.id == notice.id) {
                state.clearNotice()
            }
        }
    }

    private fun follow(level: Float) {
        val listening = output.listening ?: return

        if (level >= VOICE_LEVEL) {
            runtime.silenceJob?.cancel()
            runtime.silenceJob = null

            state.move(to = listening.copy(silenceStart = null, hasVoice = true))

            return
        }

        if (listening.hasVoice) {
            waitForSilence()
        }
    }

    private fun waitForSilence() {
        val listening = output.listening

        if (runtime.silenceJob != null || listening == null) {
            return
        }

        state.move(to = listening.copy(silenceStart = dependencies.clock.now.toEpochMilli()))

        runtime.silenceJob = dependencies.scope.launch {
            delay(SILENCE_MILLIS)
            runtime.silenceJob = null
            finish()
        }
    }

    private fun reset() {
        runtime.silenceJob?.cancel()
        runtime.silenceJob = null
        runtime.recognizer?.destroy()
        runtime.recognizer = null
        runtime.session = null
        state.move(to = Phase.Idle)
    }

    private inner class Listener : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) = Unit

        override fun onBeginningOfSpeech() = Unit

        override fun onRmsChanged(rmsdB: Float) {
            val listening = output.listening ?: return
            val level = EntryVoiceSpeech.level(rmsdB)

            state.move(to = listening.copy(levels = listOf(level) + listening.levels.dropLast(1)))
            follow(level)
        }

        override fun onBufferReceived(buffer: ByteArray?) = Unit

        override fun onEndOfSpeech() {
            finish()
        }

        override fun onError(error: Int) {
            val outcome = EntryVoiceSpeech.outcome(error = error, download = ::download)

            reset()

            if (outcome == null) {
                deny()
            } else {
                show(EntryVoiceResult(outcome = outcome, count = 0, text = ""))
            }
        }

        override fun onResults(results: Bundle?) {
            val session = runtime.session
            val candidates = results?.getStringArrayList(
                SpeechRecognizer.RESULTS_RECOGNITION,
            ).orEmpty()

            reset()

            if (session != null) {
                read(candidates = candidates, session = session)
            }
        }

        override fun onPartialResults(partialResults: Bundle?) {
            val text = partialResults
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull()
                ?: return

            when (val current = state.phase) {
                is Phase.Listening -> {
                    state.move(
                        to = current.copy(
                            transcript = text,
                            preview = runtime.session?.let {
                                it.model.output.voiceReading(text = text, today = it.today)
                            },
                        ),
                    )

                    if (text.isNotBlank() && !current.hasVoice) {
                        waitForSilence()
                    }
                }

                is Phase.Reading -> {
                    state.move(to = Phase.Reading(transcript = text))
                }

                Phase.Idle, Phase.Denied -> {}
            }
        }

        override fun onEvent(
            eventType: Int,
            params: Bundle?,
        ) = Unit
    }

    private companion object {
        const val SILENCE_MILLIS = 1_000L
        const val VOICE_LEVEL = 0.2f
        const val LEVEL_COUNT = 16

        val quietLevels: List<Float> = List(LEVEL_COUNT) { 0f }
    }
}
