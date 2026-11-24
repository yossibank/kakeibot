package com.yossibank.kakeibot.features.screens.entry.voice

import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.RecognizerIntent
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
    val input = Input(isAvailable = isOnDeviceAvailable(context))
    val output = Output(state)

    private val dependencies = Dependencies(context, scope, clock)

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

        internal var recognizer: SpeechRecognizer? = null
        internal var session: Session? = null
        internal var noticeJob: Job? = null
        internal var silenceJob: Job? = null
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

        input.recognizer = recognizer
        input.session = Session(
            model = model,
            today = today,
        )
        state.start()

        recognizer.setRecognitionListener(EntryVoiceListener(flow = this))
        recognizer.startListening(intent(hints = model.output.voiceHints))
    }

    fun deny() {
        state.move(to = Phase.Denied)
    }

    fun finish() {
        val listening = output.listening ?: return

        input.silenceJob?.cancel()
        state.finish(transcript = listening.transcript)
        input.recognizer?.stopListening()
    }

    fun cancel() {
        if (state.phase == Phase.Denied) {
            state.move(to = Phase.Idle)
            return
        }

        if (state.phase is Phase.Listening) {
            state.countEnd()
        }

        input.recognizer?.cancel()
        reset()
    }

    fun undoLast(model: EntryModel) {
        state.undo?.let(model.state::undo)
        clearNotice()
    }

    fun clearNotice() {
        input.noticeJob?.cancel()
        state.clearNotice()
    }

    fun close() {
        input.recognizer?.cancel()
        reset()
        clearNotice()
    }

    internal data class Session(
        val model: EntryModel,
        val today: LocalDate,
    )

    internal fun read(
        candidates: List<String>,
        session: Session,
    ) {
        val model = session.model
        val primary = candidates.firstOrNull()?.trim().orEmpty()

        val text = candidates
            .map { it.trim() }
            .firstOrNull {
                model.output.voiceReading(text = it, today = session.today).amount !=
                    null
            }
            ?: primary

        if (text.isEmpty()) {
            show(EntryVoiceResult(outcome = Outcome.Unheard, count = 0, text = ""))
            return
        }

        val reading = model.output.voiceReading(text = text, today = session.today)

        if (reading.isEmpty) {
            show(
                EntryVoiceResult(
                    outcome = Outcome.Unheard,
                    count = 0,
                    text = text,
                ),
            )
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

        show(
            EntryVoiceResult(
                outcome = Outcome.Applied,
                count = reading.count,
                text = text,
            ),
        )
        state.remember(undo)
    }

    internal fun download(): Outcome {
        val recognizer = input.recognizer

        if (recognizer == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return Outcome.Unsupported
        }

        recognizer.triggerModelDownload(intent(hints = emptyList()))

        return Outcome.Downloading
    }

    internal fun show(notice: EntryVoiceResult) {
        input.noticeJob?.cancel()
        state.show(notice)

        input.noticeJob = dependencies.scope.launch {
            delay(UndoNoticeState.MILLIS)

            if (state.notice?.id == notice.id) {
                state.clearNotice()
            }
        }
    }

    internal fun follow(level: Float) {
        val listening = output.listening ?: return

        if (level >= VOICE_LEVEL) {
            input.silenceJob?.cancel()
            input.silenceJob = null

            state.move(
                to = listening.copy(
                    silenceStart = null,
                    hasVoice = true,
                ),
            )

            return
        }

        if (listening.hasVoice) {
            waitForSilence()
        }
    }

    internal fun waitForSilence() {
        val listening = output.listening

        if (input.silenceJob != null || listening == null) {
            return
        }

        state.move(to = listening.copy(silenceStart = dependencies.clock.now.toEpochMilli()))

        input.silenceJob = dependencies.scope.launch {
            delay(SILENCE_MILLIS)
            input.silenceJob = null
            finish()
        }
    }

    internal fun reset() {
        input.silenceJob?.cancel()
        input.silenceJob = null
        input.recognizer?.destroy()
        input.recognizer = null
        input.session = null
        state.move(to = Phase.Idle)
    }

    private fun intent(hints: List<String>): Intent =
        Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, LANGUAGE)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, MAX_RESULTS)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                putStringArrayListExtra(RecognizerIntent.EXTRA_BIASING_STRINGS, ArrayList(hints))
            }
        }

    private companion object {
        const val LANGUAGE = "ja-JP"
        const val MAX_RESULTS = 5
        const val SILENCE_MILLIS = 1_000L
        const val VOICE_LEVEL = 0.2f
        const val LEVEL_COUNT = 16

        val quietLevels: List<Float> = List(LEVEL_COUNT) { 0f }

        fun isOnDeviceAvailable(context: Context): Boolean =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                SpeechRecognizer.isOnDeviceRecognitionAvailable(context)
    }
}
