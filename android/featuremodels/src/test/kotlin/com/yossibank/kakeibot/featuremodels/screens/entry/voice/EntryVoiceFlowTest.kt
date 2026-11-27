package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.amount
import com.yossibank.kakeibot.featuremodels.screens.entry.model.isDateFromVoice
import com.yossibank.kakeibot.featuremodels.screens.entry.model.isMemoFromVoice
import com.yossibank.kakeibot.featuremodels.screens.entry.model.isWalletFromVoice
import com.yossibank.kakeibot.featuremodels.screens.entry.model.loadedModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.store
import com.yossibank.kakeibot.featuremodels.screens.entry.model.wallets
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceResult.Outcome
import com.yossibank.kakeibot.featuremodels.shared.model.UndoNotice
import com.yossibank.kakeibot.featuremodels.support.FakeVoiceClock
import com.yossibank.kakeibot.featuremodels.support.FakeVoiceSource
import com.yossibank.kakeibot.featuremodels.support.ManualWait
import com.yossibank.kakeibot.featuremodels.support.VOICE_SILENCE_MILLIS
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.featuremodels.support.voiceFlow
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

@OptIn(ExperimentalCoroutinesApi::class)
class EntryVoiceFlowTest {
    @Before
    fun setMain() {
        Dispatchers.setMain(StandardTestDispatcher())
    }

    @After
    fun resetMain() {
        Dispatchers.resetMain()
    }

    @Test
    fun appliesSpokenFieldsAndUndoesThem() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val wallet = model.output.wallets.last()
        val source = FakeVoiceSource()
        val flow = voiceFlow(source)

        flow.start(model, today = setup.today)
        source.say("昨日コンビニで980円、${wallet.name}で")
        val previewAmount = flow.output.listening?.preview?.amount
        flow.finish()

        assertEquals(980, previewAmount)
        assertEquals(980, model.output.amount)
        assertEquals(setup.today.adding(days = -1), model.state.fields.form.date)
        assertEquals(wallet.id, model.state.fields.form.walletId)
        assertEquals("コンビニ", model.state.store)
        assertTrue(model.output.isDateFromVoice)
        assertTrue(model.output.isWalletFromVoice)
        assertTrue(model.output.isMemoFromVoice)
        assertEquals(Outcome.Applied, flow.state.notices.result.current?.outcome)
        assertEquals(4, flow.state.notices.result.current?.count)
        assertEquals("声から 4 つ入れました", flow.state.notices.result.current?.title)
        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
        assertTrue(source.isFinished)

        flow.undoLast(model)

        assertEquals(0, model.output.amount)
        assertEquals(setup.today, model.state.fields.form.date)
        assertEquals("", model.state.fields.form.memo)
        assertFalse(model.output.isDateFromVoice)
        assertNull(flow.state.notices.result.current)
    }

    @Test
    fun keepsKeypadOpenWhenAmountIsMissing() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val flow = voiceFlow(source)

        flow.start(model, today = setup.today)
        source.say("昨日のコンビニ")
        flow.finish()

        assertEquals(0, model.output.amount)
        assertEquals(setup.today.adding(days = -1), model.state.fields.form.date)
        assertEquals(EntryModel.Field.Amount, model.state.focus.field)
        assertEquals(Outcome.MissingAmount, flow.state.notices.result.current?.outcome)
        assertEquals("「昨日のコンビニ」", flow.state.notices.result.current?.message)
        assertEquals(false, flow.state.notices.result.current?.canUndo)
        assertNull(flow.state.notices.result.current?.undo)
    }

    @Test
    fun tellsWhenNothingWasHeard() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val flow = voiceFlow(FakeVoiceSource())

        flow.start(model, today = setup.today)
        flow.finish()

        assertEquals(Outcome.Unheard, flow.state.notices.result.current?.outcome)
        assertEquals("聞き取れませんでした", flow.state.notices.result.current?.title)
        assertNull(flow.state.notices.result.current?.message)
        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
    }

    @Test
    fun finishesAfterSilence() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val clock = FakeVoiceClock()
        val flow = voiceFlow(source, clock)

        flow.start(model, today = setup.today)
        source.say("500円")
        runCurrent()
        clock.advance(millis = VOICE_SILENCE_MILLIS)
        runCurrent()

        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
        assertEquals(500, model.output.amount)
        assertTrue(source.isFinished)
    }

    @Test
    fun keepsRecentLevelsWhileListening() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val flow = voiceFlow(source)

        flow.start(model, today = setup.today)
        source.hear(0.4f)
        source.hear(0.8f)
        val levels = flow.output.listening?.levels.orEmpty()
        flow.cancel()
        source.hear(0.6f)

        assertEquals(EntryVoiceFlow.Phase.Listening().levels.size, levels.size)
        assertEquals(listOf(0.8f, 0.4f, 0f), levels.take(3))
        assertNull(flow.output.listening)
    }

    @Test
    fun countsSilenceFromTheLastVoice() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val clock = FakeVoiceClock()
        val flow = voiceFlow(source, clock)

        flow.start(model, today = setup.today)
        val before = flow.output.listening?.silence?.startedAt
        source.say("500円")
        val first = flow.output.listening?.silence?.startedAt
        clock.advance(millis = 20)
        source.hear(0.8f)
        val cleared = flow.output.listening?.silence?.startedAt
        source.say("500円、カードで")
        source.hear(0f)
        val second = flow.output.listening?.silence?.startedAt
        flow.cancel()

        assertNull(before)
        assertEquals(VOICE_SILENCE_MILLIS, flow.input.silenceMillis)
        assertNotNull(first)
        assertNull(cleared)
        assertNotNull(second)
        assertTrue(second > first)
        assertNull(flow.output.listening?.silence?.startedAt)
    }

    @Test
    fun finishesWhenSilenceRunsOutBeforeTheWords() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val clock = FakeVoiceClock()
        val flow = voiceFlow(source, clock)

        flow.start(model, today = setup.today)
        source.hear(0.8f)
        source.hear(0f)
        val counting = flow.output.listening?.silence?.startedAt != null
        runCurrent()
        clock.advance(millis = VOICE_SILENCE_MILLIS)
        runCurrent()

        assertTrue(counting)
        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
        assertTrue(source.isFinished)
    }

    @Test
    fun keepsListeningWhileTheVoiceIsLoud() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val clock = FakeVoiceClock()
        val flow = voiceFlow(source, clock)

        flow.start(model, today = setup.today)
        source.say("500円")
        runCurrent()
        val isSleeping = clock.isSleeping

        repeat(6) {
            source.hear(0.8f)
            clock.advance(millis = 40)
            runCurrent()
        }

        val phase = flow.state.phase
        flow.cancel()

        assertTrue(isSleeping)
        assertFalse(clock.isSleeping)
        assertTrue(phase is EntryVoiceFlow.Phase.Listening)
        assertFalse(source.isFinished)
    }

    @Test
    fun clearsNoticeAfterAWhile() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val wait = ManualWait()
        val flow = voiceFlow(source, wait = wait)

        flow.start(model, today = setup.today)
        source.say("500円")
        flow.finish()
        wait.advance(by = UndoNotice.duration - 1.milliseconds)
        val shown = flow.state.notices.result.current != null
        wait.advance(by = 1.milliseconds)

        assertTrue(shown)
        assertNull(flow.state.notices.result.current)
    }

    @Test
    fun cancelLeavesTheEntryAsItWas() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val flow = voiceFlow(source)

        flow.start(model, today = setup.today)
        val startCount = flow.state.rounds.starts
        source.say("980円")
        flow.cancel()

        assertEquals(0, model.output.amount)
        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
        assertNull(flow.state.notices.result.current)
        assertTrue(source.isCancelled)
        assertEquals(listOf(1, 1), listOf(startCount, flow.state.rounds.ends))
    }

    @Test
    fun showsDeniedCardWhenPermissionWasRefused() = modelTest(today = "2026-10-12") {
        val flow = voiceFlow(FakeVoiceSource())

        flow.deny()
        val phase = flow.state.phase
        val isActive = flow.output.isActive
        flow.cancel()

        assertEquals(EntryVoiceFlow.Phase.Denied, phase)
        assertTrue(isActive)
        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
        assertFalse(flow.output.isActive)
        assertEquals(listOf(0, 0), listOf(flow.state.rounds.starts, flow.state.rounds.ends))
    }
}
