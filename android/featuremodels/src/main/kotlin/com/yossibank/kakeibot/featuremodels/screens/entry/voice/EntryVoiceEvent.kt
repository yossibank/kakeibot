package com.yossibank.kakeibot.featuremodels.screens.entry.voice

internal sealed interface EntryVoiceEvent {
    data object Ended : EntryVoiceEvent

    data class Level(
        val level: Float,
    ) : EntryVoiceEvent

    data class Partial(
        val text: String,
    ) : EntryVoiceEvent

    data class Results(
        val candidates: List<String>,
    ) : EntryVoiceEvent

    data class Failed(
        val error: Int,
    ) : EntryVoiceEvent
}
