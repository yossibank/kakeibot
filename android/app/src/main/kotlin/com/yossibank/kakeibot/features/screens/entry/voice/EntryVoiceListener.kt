package com.yossibank.kakeibot.features.screens.entry.voice

import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import com.yossibank.kakeibot.features.screens.entry.model.voiceReading
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceFlow.Phase
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceResult.Outcome

private const val MIN_RMS = -2f
private const val MAX_RMS = 10f

internal class EntryVoiceListener(
    private val flow: EntryVoiceFlow,
) : RecognitionListener {
    override fun onReadyForSpeech(params: Bundle?) = Unit

    override fun onBeginningOfSpeech() = Unit

    override fun onRmsChanged(rmsdB: Float) {
        val listening = flow.output.listening ?: return
        val level = ((rmsdB - MIN_RMS) / (MAX_RMS - MIN_RMS)).coerceIn(0f, 1f)

        flow.state.move(to = listening.copy(levels = listOf(level) + listening.levels.dropLast(1)))
        flow.follow(level)
    }

    override fun onBufferReceived(buffer: ByteArray?) = Unit

    override fun onEndOfSpeech() {
        flow.finish()
    }

    override fun onError(error: Int) {
        val outcome = when (error) {
            SpeechRecognizer.ERROR_NO_MATCH,
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT,
            -> Outcome.Unheard

            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> flow.download()

            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> Outcome.Unsupported

            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> null

            else -> Outcome.Failed
        }

        flow.reset()

        if (outcome == null) {
            flow.deny()
        } else {
            flow.show(EntryVoiceResult(outcome = outcome, count = 0, text = ""))
        }
    }

    override fun onResults(results: Bundle?) {
        val session = flow.input.session
        val candidates = results?.getStringArrayList(
            SpeechRecognizer.RESULTS_RECOGNITION,
        ).orEmpty()

        flow.reset()

        if (session != null) {
            flow.read(candidates = candidates, session = session)
        }
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val text = partialResults
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()
            ?: return

        when (val current = flow.state.phase) {
            is Phase.Listening -> {
                flow.state.move(
                    to = current.copy(
                        transcript = text,
                        preview = flow.input.session?.let {
                            it.model.output.voiceReading(text = text, today = it.today)
                        },
                    ),
                )

                if (text.isNotBlank() && !current.hasVoice) {
                    flow.waitForSilence()
                }
            }

            is Phase.Reading -> {
                flow.state.move(to = Phase.Reading(transcript = text))
            }

            Phase.Idle, Phase.Denied -> {}
        }
    }

    override fun onEvent(
        eventType: Int,
        params: Bundle?,
    ) = Unit
}
