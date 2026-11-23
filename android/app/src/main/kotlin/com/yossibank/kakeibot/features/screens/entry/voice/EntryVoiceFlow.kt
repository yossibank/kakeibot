package com.yossibank.kakeibot.features.screens.entry.voice

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.UUID

class EntryVoiceFlow(
    private val context: Context,
    private val scope: CoroutineScope,
) {
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

    val isAvailable: Boolean = isOnDeviceAvailable(context)

    var phase: Phase by mutableStateOf(Phase.Idle)
        private set

    var notice: EntryVoiceResult? by mutableStateOf(null)
        private set

    var startCount: Int by mutableStateOf(0)
        private set

    var endCount: Int by mutableStateOf(0)
        private set

    val isActive: Boolean
        get() = phase != Phase.Idle

    val listening: Phase.Listening?
        get() = phase as? Phase.Listening

    val silenceMillis: Long
        get() = SILENCE_MILLIS

    private var recognizer: SpeechRecognizer? = null
    private var session: Session? = null
    private var undo: VoiceUndo? = null
    private var noticeJob: Job? = null
    private var silenceJob: Job? = null

    fun start(
        model: EntryModel,
        today: LocalDate,
    ) {
        if (isActive || !isAvailable || Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return
        }

        clearNotice()
        model.focus(EntryModel.Field.Amount)

        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)

        this.recognizer = recognizer
        session = Session(
            model = model,
            today = today,
        )
        phase = Phase.Listening()
        startCount += 1

        recognizer.setRecognitionListener(Listener())
        recognizer.startListening(intent(hints = model.voiceHints))
    }

    fun deny() {
        phase = Phase.Denied
    }

    fun finish() {
        val listening = listening ?: return

        silenceJob?.cancel()
        phase = Phase.Reading(transcript = listening.transcript)
        endCount += 1
        recognizer?.stopListening()
    }

    fun cancel() {
        if (phase == Phase.Denied) {
            phase = Phase.Idle
            return
        }

        if (phase is Phase.Listening) {
            endCount += 1
        }

        recognizer?.cancel()
        reset()
    }

    fun undoLast(model: EntryModel) {
        undo?.let(model::undo)
        clearNotice()
    }

    fun clearNotice() {
        noticeJob?.cancel()
        notice = null
        undo = null
    }

    fun close() {
        recognizer?.cancel()
        reset()
        clearNotice()
    }

    private data class Session(
        val model: EntryModel,
        val today: LocalDate,
    )

    private inner class Listener : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) = Unit

        override fun onBeginningOfSpeech() = Unit

        override fun onRmsChanged(rmsdB: Float) {
            val listening = listening ?: return
            val level = ((rmsdB - MIN_RMS) / (MAX_RMS - MIN_RMS)).coerceIn(0f, 1f)

            phase = listening.copy(levels = listOf(level) + listening.levels.dropLast(1))
            follow(level)
        }

        override fun onBufferReceived(buffer: ByteArray?) = Unit

        override fun onEndOfSpeech() {
            finish()
        }

        override fun onError(error: Int) {
            val outcome = when (error) {
                SpeechRecognizer.ERROR_NO_MATCH,
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT,
                -> Outcome.Unheard

                SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> download()

                SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> Outcome.Unsupported

                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> null

                else -> Outcome.Failed
            }

            reset()

            if (outcome == null) {
                deny()
            } else {
                show(EntryVoiceResult(outcome = outcome, count = 0, text = ""))
            }
        }

        override fun onResults(results: Bundle?) {
            val session = session
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

            when (val current = phase) {
                is Phase.Listening -> {
                    phase = current.copy(
                        transcript = text,
                        preview = session?.let {
                            it.model.voiceReading(text = text, today = it.today)
                        },
                    )

                    if (text.isNotBlank() && !current.hasVoice) {
                        waitForSilence()
                    }
                }

                is Phase.Reading -> {
                    phase = Phase.Reading(transcript = text)
                }

                Phase.Idle, Phase.Denied -> {}
            }
        }

        override fun onEvent(
            eventType: Int,
            params: Bundle?,
        ) = Unit
    }

    private fun read(
        candidates: List<String>,
        session: Session,
    ) {
        val model = session.model
        val primary = candidates.firstOrNull()?.trim().orEmpty()

        val text = candidates
            .map { it.trim() }
            .firstOrNull { model.voiceReading(text = it, today = session.today).amount != null }
            ?: primary

        if (text.isEmpty()) {
            show(EntryVoiceResult(outcome = Outcome.Unheard, count = 0, text = ""))
            return
        }

        val reading = model.voiceReading(text = text, today = session.today)

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
        this.undo = undo
    }

    private fun download(): Outcome {
        val recognizer = recognizer

        if (recognizer == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return Outcome.Unsupported
        }

        recognizer.triggerModelDownload(intent(hints = emptyList()))

        return Outcome.Downloading
    }

    private fun show(notice: EntryVoiceResult) {
        noticeJob?.cancel()
        this.notice = notice

        noticeJob = scope.launch {
            delay(UndoNoticeState.MILLIS)

            if (this@EntryVoiceFlow.notice?.id == notice.id) {
                this@EntryVoiceFlow.notice = null
                undo = null
            }
        }
    }

    private fun follow(level: Float) {
        val listening = listening ?: return

        if (level >= VOICE_LEVEL) {
            silenceJob?.cancel()
            silenceJob = null

            phase = listening.copy(
                silenceStart = null,
                hasVoice = true,
            )

            return
        }

        if (listening.hasVoice) {
            waitForSilence()
        }
    }

    private fun waitForSilence() {
        val listening = listening

        if (silenceJob != null || listening == null) {
            return
        }

        phase = listening.copy(silenceStart = System.currentTimeMillis())

        silenceJob = scope.launch {
            delay(SILENCE_MILLIS)
            silenceJob = null
            finish()
        }
    }

    private fun reset() {
        silenceJob?.cancel()
        silenceJob = null
        recognizer?.destroy()
        recognizer = null
        session = null
        phase = Phase.Idle
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
        const val MIN_RMS = -2f
        const val MAX_RMS = 10f
        const val LEVEL_COUNT = 16

        val quietLevels: List<Float> = List(LEVEL_COUNT) { 0f }

        fun isOnDeviceAvailable(context: Context): Boolean =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                SpeechRecognizer.isOnDeviceRecognitionAvailable(context)
    }
}
