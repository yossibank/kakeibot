package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer

internal class EntryVoiceListener(
    private val receive: (EntryVoiceEvent) -> Unit,
) : RecognitionListener {
    override fun onReadyForSpeech(params: Bundle?) = Unit

    override fun onBeginningOfSpeech() = Unit

    override fun onRmsChanged(rmsdB: Float) {
        receive(EntryVoiceEvent.Level(EntryVoiceSpeech.level(rmsdB)))
    }

    override fun onBufferReceived(buffer: ByteArray?) = Unit

    override fun onEndOfSpeech() {
        receive(EntryVoiceEvent.Ended)
    }

    override fun onError(error: Int) {
        receive(EntryVoiceEvent.Failed(error))
    }

    override fun onResults(results: Bundle?) {
        val candidates = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        receive(EntryVoiceEvent.Results(candidates.orEmpty()))
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val text = partialResults
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()
            ?: return

        receive(EntryVoiceEvent.Partial(text))
    }

    override fun onEvent(
        eventType: Int,
        params: Bundle?,
    ) = Unit
}
