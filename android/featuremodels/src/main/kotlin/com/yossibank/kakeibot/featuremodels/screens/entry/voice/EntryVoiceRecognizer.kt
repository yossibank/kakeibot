package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import android.content.Context
import android.os.Build
import android.speech.SpeechRecognizer
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceResult.Outcome

internal class EntryVoiceRecognizer private constructor(
    private val recognizer: SpeechRecognizer,
) : EntryVoiceSource {
    companion object {
        fun make(context: Context): EntryVoiceSource? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                return null
            }

            return EntryVoiceRecognizer(SpeechRecognizer.createOnDeviceSpeechRecognizer(context))
        }
    }

    override fun start(
        hints: List<String>,
        receive: (EntryVoiceEvent) -> Unit,
    ) {
        recognizer.setRecognitionListener(EntryVoiceListener(receive))
        recognizer.startListening(EntryVoiceSpeech.intent(hints = hints))
    }

    override fun finish() {
        recognizer.stopListening()
    }

    override fun cancel() {
        recognizer.cancel()
    }

    override fun close() {
        recognizer.destroy()
    }

    override fun download(): Outcome = EntryVoiceSpeech.download(recognizer)
}
