package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.voice.VoiceReading
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.VoiceUndo
import com.yossibank.kakeibot.featuremodels.screens.entry.model.undo
import com.yossibank.kakeibot.featuremodels.screens.entry.model.voiceHints
import com.yossibank.kakeibot.featuremodels.screens.entry.model.voiceReading
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import com.yossibank.kakeibot.featuremodels.shared.model.UndoNotice
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay

class EntryVoiceFlow internal constructor(
    isAvailable: Boolean,
    clock: ScreenClock,
    makeSource: () -> EntryVoiceSource?,
    sleep: suspend (Long) -> Unit,
    silenceMillis: Long,
    noticeMillis: Long,
) : ScreenPerforming {
    val state = State()
    val input = Input(isAvailable, silenceMillis)
    val output = Output(state)

    private val runtime = Runtime()

    private val dependencies = Dependencies(
        clock = clock,
        makeSource = makeSource,
        sleep = sleep,
        noticeMillis = noticeMillis,
    )

    constructor(
        context: Context,
        clock: ScreenClock,
    ) : this(
        isAvailable = EntryVoiceSpeech.isAvailable(context),
        clock = clock,
        makeSource = { EntryVoiceRecognizer.make(context) },
        sleep = { millis -> delay(millis) },
        silenceMillis = SILENCE_MILLIS,
        noticeMillis = UndoNotice.duration.inWholeMilliseconds,
    )

    sealed interface Phase {
        data object Idle : Phase

        data object Denied : Phase

        data class Listening(
            val transcript: String = "",
            val preview: VoiceReading? = null,
            val levels: List<Float> = quietLevels,
            val silence: Silence = Silence(),
            val hasVoice: Boolean = false,
        ) : Phase

        data class Reading(
            val transcript: String,
        ) : Phase
    }

    data class Silence(
        val startedAt: Long? = null,
    ) {
        fun started(at: Long): Silence = copy(startedAt = at)

        fun cleared(): Silence = copy(startedAt = null)
    }

    data class Rounds(
        val starts: Int = 0,
        val ends: Int = 0,
    ) {
        fun started(): Rounds = copy(starts = starts + 1)

        fun ended(): Rounds = copy(ends = ends + 1)
    }

    class State {
        var phase: Phase by mutableStateOf(Phase.Idle)
            private set

        var notice: EntryVoiceResult? by mutableStateOf(null)
            private set

        var rounds: Rounds by mutableStateOf(Rounds())
            private set

        var undo: VoiceUndo? = null
            private set

        fun start() {
            phase = Phase.Listening()
            rounds = rounds.started()
        }

        fun finish(transcript: String) {
            phase = Phase.Reading(transcript = transcript)
            rounds = rounds.ended()
        }

        fun countEnd() {
            rounds = rounds.ended()
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
        val silenceMillis: Long,
    )

    class Output(
        private val state: State,
    ) {
        val isActive: Boolean
            get() = state.phase != Phase.Idle

        val listening: Phase.Listening?
            get() = state.phase as? Phase.Listening
    }

    private class Dependencies(
        val clock: ScreenClock,
        val makeSource: () -> EntryVoiceSource?,
        val sleep: suspend (Long) -> Unit,
        val noticeMillis: Long,
    )

    private class Runtime {
        var source: EntryVoiceSource? = null
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
        if (output.isActive || !input.isAvailable) {
            return
        }

        val source = dependencies.makeSource() ?: return

        clearNotice()
        model.state.focus(EntryModel.Field.Amount)
        runtime.source = source

        runtime.session = Session(
            model = model,
            today = today,
        )

        state.start()

        source.start(
            hints = model.output.voiceHints,
            receive = ::receive,
        )
    }

    fun deny() {
        state.move(to = Phase.Denied)
    }

    fun finish() {
        val listening = output.listening ?: return

        runtime.silenceJob?.cancel()
        state.finish(transcript = listening.transcript)
        runtime.source?.finish()
    }

    fun cancel() {
        if (state.phase == Phase.Denied) {
            state.move(to = Phase.Idle)
            return
        }

        if (state.phase is Phase.Listening) {
            state.countEnd()
        }

        runtime.source?.cancel()
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
        runtime.source?.cancel()
        reset()
        clearNotice()
    }

    fun silencePassed(since: Long): Long =
        (dependencies.clock.now.toEpochMilli() - since).coerceIn(0L, input.silenceMillis)

    private fun receive(event: EntryVoiceEvent) {
        when (event) {
            is EntryVoiceEvent.Level -> hear(event.level)
            is EntryVoiceEvent.Partial -> preview(event.text)
            is EntryVoiceEvent.Results -> conclude(event.candidates)
            is EntryVoiceEvent.Failed -> fail(event.error)
            EntryVoiceEvent.Ended -> finish()
        }
    }

    private fun hear(level: Float) {
        val listening = output.listening ?: return
        state.move(to = listening.copy(levels = listOf(level) + listening.levels.dropLast(1)))
        follow(level)
    }

    private fun preview(text: String) {
        when (val current = state.phase) {
            is Phase.Listening -> {
                state.move(
                    to = current.copy(
                        transcript = text,
                        preview = runtime.session?.let { session ->
                            session.model.output.voiceReading(
                                text = text,
                                today = session.today,
                            )
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

    private fun conclude(candidates: List<String>) {
        val session = runtime.session

        reset()

        if (session == null) {
            return
        }

        val read = session.model.read(
            candidates = candidates,
            today = session.today,
        )

        show(read.result)
        read.undo?.let(state::remember)
    }

    private fun fail(error: Int) {
        val outcome = EntryVoiceSpeech.outcome(error = error) {
            runtime.source?.download() ?: EntryVoiceResult.Outcome.Unsupported
        }

        reset()

        if (outcome == null) {
            deny()
            return
        }

        show(
            EntryVoiceResult(
                outcome = outcome,
                count = 0,
                text = "",
            ),
        )
    }

    private fun show(notice: EntryVoiceResult) {
        runtime.noticeJob?.cancel()
        state.show(notice)

        runtime.noticeJob = perform {
            dependencies.sleep(dependencies.noticeMillis)

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

            state.move(
                to = listening.copy(
                    silence = listening.silence.cleared(),
                    hasVoice = true,
                ),
            )

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

        state.move(
            to = listening.copy(
                silence = listening.silence.started(at = dependencies.clock.now.toEpochMilli()),
            ),
        )

        runtime.silenceJob = perform {
            dependencies.sleep(input.silenceMillis)
            runtime.silenceJob = null
            finish()
        }
    }

    private fun reset() {
        runtime.silenceJob?.cancel()
        runtime.silenceJob = null
        runtime.source?.close()
        runtime.source = null
        runtime.session = null
        state.move(to = Phase.Idle)
    }

    private companion object {
        const val SILENCE_MILLIS = 1_000L
        const val VOICE_LEVEL = 0.2f
        const val LEVEL_COUNT = 16

        val quietLevels: List<Float> = List(LEVEL_COUNT) { 0f }
    }
}
