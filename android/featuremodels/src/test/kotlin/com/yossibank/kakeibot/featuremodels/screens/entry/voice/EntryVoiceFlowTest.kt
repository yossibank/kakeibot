package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import android.content.ContextWrapper
import com.yossibank.kakeibot.featuremodels.screens.entry.model.loadedModel
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.modelTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryVoiceFlowTest {
    @Test
    fun cancelLeavesTheEntryAsItWas() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val flow = setup.voiceFlow()

        flow.state.start()
        val isListening = flow.output.listening != null
        flow.cancel()

        assertTrue(isListening)
        assertEquals(0, model.output.amount)
        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
        assertNull(flow.state.notice)
        assertEquals(listOf(1, 1), listOf(flow.state.startCount, flow.state.endCount))
    }

    @Test
    fun showsDeniedCardWhenPermissionWasRefused() = modelTest(today = "2026-10-12") { setup ->
        val flow = setup.voiceFlow()

        flow.deny()
        val phase = flow.state.phase
        val isActive = flow.output.isActive
        flow.cancel()

        assertEquals(EntryVoiceFlow.Phase.Denied, phase)
        assertTrue(isActive)
        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
        assertFalse(flow.output.isActive)
        assertEquals(listOf(0, 0), listOf(flow.state.startCount, flow.state.endCount))
    }
}

private fun ModelTestSetup.voiceFlow(): EntryVoiceFlow = EntryVoiceFlow(
    context = ContextWrapper(null),
    clock = ScreenClock.fixed(now),
)
