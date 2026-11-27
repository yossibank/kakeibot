package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import org.junit.Test
import kotlin.test.assertEquals

class RoundsTest {
    @Test
    fun countsStartsAndEndsApart() {
        val rounds = EntryVoiceFlow.Rounds()
            .started()
            .ended()
            .ended()

        assertEquals(EntryVoiceFlow.Rounds(starts = 1, ends = 2), rounds)
    }
}
