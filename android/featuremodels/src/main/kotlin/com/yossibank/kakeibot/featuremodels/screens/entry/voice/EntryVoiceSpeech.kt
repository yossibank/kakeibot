package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceResult.Outcome

internal object EntryVoiceSpeech {
    private const val LANGUAGE = "ja-JP"
    private const val MAX_RESULTS = 5
    private const val MIN_RMS = -2f
    private const val MAX_RMS = 10f

    fun isAvailable(context: Context): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        SpeechRecognizer.isOnDeviceRecognitionAvailable(context)

    fun level(rmsdB: Float): Float = ((rmsdB - MIN_RMS) / (MAX_RMS - MIN_RMS)).coerceIn(0f, 1f)

    fun text(
        candidates: List<String>,
        isReadable: (String) -> Boolean,
    ): String = candidates.map { it.trim() }.firstOrNull(isReadable)
        ?: candidates.firstOrNull()?.trim().orEmpty()

    fun outcome(
        error: Int,
        download: () -> Outcome,
    ): Outcome? = when (error) {
        SpeechRecognizer.ERROR_NO_MATCH,
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT,
        -> Outcome.Unheard

        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> download()

        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> Outcome.Unsupported

        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> null

        else -> Outcome.Failed
    }

    fun download(recognizer: SpeechRecognizer): Outcome {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return Outcome.Unsupported
        }

        recognizer.triggerModelDownload(intent(hints = emptyList()))

        return Outcome.Downloading
    }

    fun intent(hints: List<String>): Intent =
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
}
