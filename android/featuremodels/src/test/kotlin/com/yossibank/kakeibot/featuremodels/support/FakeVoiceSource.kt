package com.yossibank.kakeibot.featuremodels.support

import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceEvent
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceResult.Outcome
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceSource

internal class FakeVoiceSource : EntryVoiceSource {
    var isFinished = false
        private set

    var isCancelled = false
        private set

    var finalCandidates: List<String>? = null

    private var receive: ((EntryVoiceEvent) -> Unit)? = null
    private var said: List<String> = emptyList()

    override fun start(
        hints: List<String>,
        receive: (EntryVoiceEvent) -> Unit,
    ) {
        this.receive = receive
    }

    override fun finish() {
        isFinished = true
        receive?.invoke(EntryVoiceEvent.Results(finalCandidates ?: said))
    }

    override fun cancel() {
        isCancelled = true
    }

    override fun close() = Unit

    override fun download(): Outcome = Outcome.Unsupported

    fun hear(level: Float) {
        receive?.invoke(EntryVoiceEvent.Level(level))
    }

    fun say(
        text: String,
        alternatives: List<String> = emptyList(),
    ) {
        said = listOf(text) + alternatives
        receive?.invoke(EntryVoiceEvent.Partial(text))
    }
}
