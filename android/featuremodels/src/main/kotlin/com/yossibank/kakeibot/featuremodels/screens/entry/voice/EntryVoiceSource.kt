package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceResult.Outcome

internal interface EntryVoiceSource {
    fun start(
        hints: List<String>,
        receive: (EntryVoiceEvent) -> Unit,
    )

    fun finish()

    fun cancel()

    fun close()

    fun download(): Outcome
}
