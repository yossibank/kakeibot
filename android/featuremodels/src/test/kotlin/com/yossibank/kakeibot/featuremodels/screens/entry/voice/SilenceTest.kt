package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class SilenceTest {
    @Test
    fun startsAndClearsSilence() {
        val silence = EntryVoiceFlow.Silence()
        val started = silence.started(at = 100L)
        val cleared = started.cleared()

        assertNull(silence.startedAt)
        assertEquals(100L, started.startedAt)
        assertNull(cleared.startedAt)
    }
}
