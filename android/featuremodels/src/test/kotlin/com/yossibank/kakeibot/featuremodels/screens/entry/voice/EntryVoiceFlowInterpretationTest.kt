package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import com.yossibank.kakeibot.featuremodels.screens.entry.model.amount
import com.yossibank.kakeibot.featuremodels.screens.entry.model.loadedModel
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceResult.Outcome
import com.yossibank.kakeibot.featuremodels.support.FakeVoiceSource
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.featuremodels.support.voiceFlow
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalCoroutinesApi::class)
class EntryVoiceFlowInterpretationTest {
    @Before
    fun setMain() {
        Dispatchers.setMain(StandardTestDispatcher())
    }

    @After
    fun resetMain() {
        Dispatchers.resetMain()
    }

    @Test
    fun readsTheAmountFromAnAlternative() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val flow = voiceFlow(source)

        flow.start(model, today = setup.today)
        source.say("ランチ休憩", alternatives = listOf("ランチ990円"))
        flow.finish()

        assertEquals(990, model.output.amount)
        assertEquals("ランチ990円", flow.state.notice?.text)
    }

    @Test
    fun readsTheLastResultGivenWhileFinishing() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val flow = voiceFlow(source)
        source.finalCandidates = listOf("コンビニで", "コンビニで980円")

        flow.start(model, today = setup.today)
        source.say("コンビニで")
        flow.finish()

        assertEquals(980, model.output.amount)
        assertEquals(Outcome.Applied, flow.state.notice?.outcome)
    }
}
