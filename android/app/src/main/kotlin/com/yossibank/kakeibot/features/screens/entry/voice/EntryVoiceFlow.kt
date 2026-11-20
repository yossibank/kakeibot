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
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.model.VoiceUndo
import com.yossibank.kakeibot.features.screens.entry.model.apply
import com.yossibank.kakeibot.features.screens.entry.model.undo
import com.yossibank.kakeibot.features.screens.entry.model.voiceHints
import com.yossibank.kakeibot.features.screens.entry.model.voiceReading
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.UUID

class EntryVoiceFlow(
    private val context: Context,
    private val scope: CoroutineScope,
) {
    enum class Step {
        Listening,
        Reading,
        Denied,
    }

    enum class Outcome {
        Applied,
        MissingAmount,
        Unheard,
        Failed,
        Downloading,
        Unsupported,
    }

    data class Notice(
        val outcome: Outcome,
        val count: Int,
        val text: String,
        val id: UUID = UUID.randomUUID(),
    ) {
        val title: String
            get() = when (outcome) {
                Outcome.Applied -> "声から $count つ入れました"
                Outcome.MissingAmount -> "金額が聞き取れませんでした"
                Outcome.Unheard -> if (text.isEmpty()) "聞き取れませんでした" else "入れられる項目がありませんでした"
                Outcome.Failed -> "声を聞き取れませんでした。もう一度押してください"
                Outcome.Downloading -> "日本語の音声認識を準備しています"
                Outcome.Unsupported -> "この端末では日本語の音声認識が使えません"
            }

        val message: String?
            get() = if (text.isEmpty()) null else "「$text」"

        val hint: String?
            get() = when (outcome) {
                Outcome.Applied -> null
                Outcome.Downloading -> "日本語のデータを入れ終えてから、もう一度押してください"
                Outcome.Unsupported -> "テンキーで入れてください"
                else -> "もう一度「声」を押して話すか、テンキーで入れてください"
            }

        val canUndo: Boolean
            get() = outcome == Outcome.Applied
    }

    val isAvailable: Boolean = isOnDeviceAvailable(context)

    var step: Step? by mutableStateOf(null)
        private set

    var transcript: String by mutableStateOf("")
        private set

    var preview: VoiceReading? by mutableStateOf(null)
        private set

    var levels: List<Float> by mutableStateOf(quietLevels)
        private set

    var notice: Notice? by mutableStateOf(null)
        private set

    var silenceStart: Long? by mutableStateOf(null)
        private set

    var startCount: Int by mutableStateOf(0)
        private set

    var endCount: Int by mutableStateOf(0)
        private set

    val isActive: Boolean
        get() = step != null

    val silenceMillis: Long
        get() = SILENCE_MILLIS

    private var recognizer: SpeechRecognizer? = null
    private var session: Session? = null
    private var undo: VoiceUndo? = null
    private var noticeJob: Job? = null
    private var silenceJob: Job? = null
    private var hasVoice = false

    fun start(
        model: EntryModel,
        today: LocalDate,
    ) {
        if (step != null || !isAvailable || Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
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
        transcript = ""
        preview = null
        step = Step.Listening
        startCount += 1

        recognizer.setRecognitionListener(Listener())
        recognizer.startListening(intent(hints = model.voiceHints))
    }

    fun deny() {
        step = Step.Denied
    }

    fun finish() {
        if (step != Step.Listening) {
            return
        }

        silenceJob?.cancel()
        silenceStart = null
        step = Step.Reading
        levels = quietLevels
        endCount += 1
        recognizer?.stopListening()
    }

    fun cancel() {
        if (step == Step.Denied) {
            step = null
            return
        }

        if (step == Step.Listening) {
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
            if (step != Step.Listening) {
                return
            }

            val level = ((rmsdB - MIN_RMS) / (MAX_RMS - MIN_RMS)).coerceIn(0f, 1f)
            levels = listOf(level) + levels.dropLast(1)
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
                show(Notice(outcome = outcome, count = 0, text = ""))
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

            transcript = text
            preview = session?.let { it.model.voiceReading(text = text, today = it.today) }

            if (step == Step.Listening && text.isNotBlank() && !hasVoice) {
                waitForSilence()
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
            show(Notice(outcome = Outcome.Unheard, count = 0, text = ""))
            return
        }

        val reading = model.voiceReading(text = text, today = session.today)

        if (reading.isEmpty) {
            show(Notice(outcome = Outcome.Unheard, count = 0, text = text))
            return
        }

        val undo = model.apply(reading)

        if (reading.amount == null) {
            show(Notice(outcome = Outcome.MissingAmount, count = reading.count, text = text))
            return
        }

        show(Notice(outcome = Outcome.Applied, count = reading.count, text = text))
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

    private fun show(notice: Notice) {
        noticeJob?.cancel()
        this.notice = notice

        noticeJob = scope.launch {
            delay(NOTICE_MILLIS)

            if (this@EntryVoiceFlow.notice?.id == notice.id) {
                this@EntryVoiceFlow.notice = null
                undo = null
            }
        }
    }

    private fun follow(level: Float) {
        if (level >= VOICE_LEVEL) {
            hasVoice = true
            silenceJob?.cancel()
            silenceJob = null
            silenceStart = null
            return
        }

        if (hasVoice) {
            waitForSilence()
        }
    }

    private fun waitForSilence() {
        if (silenceJob != null) {
            return
        }

        silenceStart = System.currentTimeMillis()

        silenceJob = scope.launch {
            delay(SILENCE_MILLIS)
            silenceJob = null
            finish()
        }
    }

    private fun reset() {
        silenceJob?.cancel()
        silenceJob = null
        silenceStart = null
        hasVoice = false
        recognizer?.destroy()
        recognizer = null
        session = null
        step = null
        preview = null
        transcript = ""
        levels = quietLevels
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
        const val NOTICE_MILLIS = 4_000L
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
