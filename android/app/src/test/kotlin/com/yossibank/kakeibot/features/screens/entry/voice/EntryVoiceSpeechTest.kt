package com.yossibank.kakeibot.features.screens.entry.voice

import android.speech.SpeechRecognizer
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceResult.Outcome
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryVoiceSpeechTest {
    @Test
    fun scalesLevelIntoRange() {
        assertEquals(0f, EntryVoiceSpeech.level(rmsdB = -5f))
        assertEquals(0.5f, EntryVoiceSpeech.level(rmsdB = 4f))
        assertEquals(1f, EntryVoiceSpeech.level(rmsdB = 20f))
    }

    @Test
    fun picksFirstReadableCandidate() {
        val text = EntryVoiceSpeech.text(
            candidates = listOf(" こんびに ", " コンビニで500円 "),
            isReadable = { it.contains("円") },
        )

        assertEquals("コンビニで500円", text)
    }

    @Test
    fun fallsBackToFirstCandidate() {
        val text = EntryVoiceSpeech.text(
            candidates = listOf(" こんびに ", "コンビニ"),
            isReadable = { false },
        )

        assertEquals("こんびに", text)
        assertEquals("", EntryVoiceSpeech.text(candidates = emptyList(), isReadable = { true }))
    }

    @Test
    fun mapsRecognizerErrorsToOutcome() {
        val download = { Outcome.Downloading }

        assertEquals(
            Outcome.Unheard,
            EntryVoiceSpeech.outcome(SpeechRecognizer.ERROR_NO_MATCH, download),
        )
        assertEquals(
            Outcome.Unheard,
            EntryVoiceSpeech.outcome(SpeechRecognizer.ERROR_SPEECH_TIMEOUT, download),
        )
        assertEquals(
            Outcome.Downloading,
            EntryVoiceSpeech.outcome(SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE, download),
        )
        assertEquals(
            Outcome.Unsupported,
            EntryVoiceSpeech.outcome(SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED, download),
        )
        assertNull(
            EntryVoiceSpeech.outcome(SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS, download),
        )
        assertEquals(
            Outcome.Failed,
            EntryVoiceSpeech.outcome(SpeechRecognizer.ERROR_NETWORK, download),
        )
    }

    @Test
    fun describesResult() {
        val applied = EntryVoiceResult(outcome = Outcome.Applied, count = 4, text = "昨日のコンビニ")
        val missing = EntryVoiceResult(outcome = Outcome.MissingAmount, count = 1, text = "昨日のコンビニ")
        val unheard = EntryVoiceResult(outcome = Outcome.Unheard, count = 0, text = "")

        assertEquals("声から 4 つ入れました", applied.title)
        assertTrue(applied.canUndo)
        assertNull(applied.hint)
        assertEquals("「昨日のコンビニ」", missing.message)
        assertFalse(missing.canUndo)
        assertEquals("聞き取れませんでした", unheard.title)
        assertNull(unheard.message)
    }
}
