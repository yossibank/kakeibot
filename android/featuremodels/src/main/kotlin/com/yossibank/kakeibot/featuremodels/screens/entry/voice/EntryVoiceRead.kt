package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.apply
import com.yossibank.kakeibot.featuremodels.screens.entry.model.voiceReading
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceResult.Outcome

internal fun EntryModel.read(
    candidates: List<String>,
    today: LocalDate,
): EntryVoiceResult {
    val text = EntryVoiceSpeech.text(candidates = candidates) { candidate ->
        val heard = output.voiceReading(
            text = candidate,
            today = today,
        )

        heard.amount != null
    }

    if (text.isEmpty()) {
        return unheard(text = "")
    }

    val reading = output.voiceReading(
        text = text,
        today = today,
    )

    if (reading.isEmpty) {
        return unheard(text = text)
    }

    val undo = apply(reading)

    if (reading.amount == null) {
        return EntryVoiceResult(
            outcome = Outcome.MissingAmount,
            count = reading.count,
            text = text,
        )
    }

    return EntryVoiceResult(
        outcome = Outcome.Applied,
        count = reading.count,
        text = text,
        undo = undo,
    )
}

private fun unheard(text: String): EntryVoiceResult = EntryVoiceResult(
    outcome = Outcome.Unheard,
    count = 0,
    text = text,
)
