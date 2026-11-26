package com.yossibank.kakeibot.featuremodels.screens.entry.voice

import com.yossibank.kakeibot.featuremodels.screens.entry.model.amount
import com.yossibank.kakeibot.featuremodels.screens.entry.model.loadedModel
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceResult.Outcome
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.support.ModelTestDatabase
import com.yossibank.kakeibot.featuremodels.support.modelTest
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.time.Instant
import kotlin.coroutines.resume
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

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

    @Test
    fun finishesAfterSilence() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val clock = FakeVoiceClock()
        val flow = voiceFlow(source, clock)

        flow.start(model, today = setup.today)
        source.say("500円")
        runCurrent()
        clock.advance(millis = SILENCE_MILLIS)
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
        val before = flow.output.listening?.silenceStart
        source.say("500円")
        val first = flow.output.listening?.silenceStart
        clock.advance(millis = 20)
        source.hear(0.8f)
        val cleared = flow.output.listening?.silenceStart
        source.say("500円、カードで")
        source.hear(0f)
        val second = flow.output.listening?.silenceStart
        flow.cancel()

        assertNull(before)
        assertEquals(SILENCE_MILLIS, flow.input.silenceMillis)
        assertNotNull(first)
        assertNull(cleared)
        assertNotNull(second)
        assertTrue(second > first)
        assertNull(flow.output.listening?.silenceStart)
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
        val counting = flow.output.listening?.silenceStart != null
        runCurrent()
        clock.advance(millis = SILENCE_MILLIS)
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
        val clock = FakeVoiceClock()
        val flow = voiceFlow(source, clock)

        flow.start(model, today = setup.today)
        source.say("500円")
        flow.finish()
        runCurrent()
        val shown = flow.state.notice != null
        clock.advance(millis = NOTICE_MILLIS)
        runCurrent()

        assertTrue(shown)
        assertNull(flow.state.notice)
    }

    @Test
    fun cancelLeavesTheEntryAsItWas() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val source = FakeVoiceSource()
        val flow = voiceFlow(source)

        flow.start(model, today = setup.today)
        val startCount = flow.state.startCount
        source.say("980円")
        flow.cancel()

        assertEquals(0, model.output.amount)
        assertEquals(EntryVoiceFlow.Phase.Idle, flow.state.phase)
        assertNull(flow.state.notice)
        assertTrue(source.isCancelled)
        assertEquals(listOf(1, 1), listOf(startCount, flow.state.endCount))
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
        assertEquals(listOf(0, 0), listOf(flow.state.startCount, flow.state.endCount))
    }
}

private const val SILENCE_MILLIS = 100L
private const val NOTICE_MILLIS = 100L

private fun voiceFlow(
    source: FakeVoiceSource,
    clock: FakeVoiceClock = FakeVoiceClock(),
): EntryVoiceFlow = EntryVoiceFlow(
    isAvailable = true,
    clock = clock.screenClock,
    makeSource = { source },
    sleep = clock::sleep,
    silenceMillis = SILENCE_MILLIS,
    noticeMillis = NOTICE_MILLIS,
)

private class FakeVoiceSource : EntryVoiceSource {
    var isFinished = false
        private set

    var isCancelled = false
        private set

    var finalCandidates: List<String>? = null

    private var receive: ((EntryVoiceEvent) -> Unit)? = null
    private var said: String? = null

    override fun start(
        hints: List<String>,
        receive: (EntryVoiceEvent) -> Unit,
    ) {
        this.receive = receive
    }

    override fun finish() {
        isFinished = true
        receive?.invoke(EntryVoiceEvent.Results(finalCandidates ?: listOfNotNull(said)))
    }

    override fun cancel() {
        isCancelled = true
    }

    override fun close() = Unit

    override fun download(): Outcome = Outcome.Unsupported

    fun hear(level: Float) {
        receive?.invoke(EntryVoiceEvent.Level(level))
    }

    fun say(text: String) {
        said = text
        receive?.invoke(EntryVoiceEvent.Partial(text))
    }
}

private class FakeVoiceClock {
    val screenClock = ScreenClock { time }

    private val sleepers = mutableMapOf<Int, Sleeper>()
    private var time: Instant = ModelTestDatabase.now
    private var nextId = 0

    val isSleeping: Boolean
        get() = sleepers.isNotEmpty()

    private class Sleeper(
        val deadline: Instant,
        val continuation: CancellableContinuation<Unit>,
    )

    suspend fun sleep(millis: Long) {
        val id = nextId
        val deadline = time.plusMillis(millis)

        nextId += 1

        suspendCancellableCoroutine { continuation ->
            sleepers[id] = Sleeper(
                deadline = deadline,
                continuation = continuation,
            )

            continuation.invokeOnCancellation {
                sleepers.remove(id)
            }
        }
    }

    fun advance(millis: Long) {
        time = time.plusMillis(millis)

        val woken = sleepers.filterValues { it.deadline <= time }

        woken.keys.forEach(sleepers::remove)
        woken.values.forEach { it.continuation.resume(Unit) }
    }
}
