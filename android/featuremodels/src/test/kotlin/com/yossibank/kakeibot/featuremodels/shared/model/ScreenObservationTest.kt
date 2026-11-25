package com.yossibank.kakeibot.featuremodels.shared.model

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.io.IOException
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class ScreenObservationTest {
    @Test
    fun resubscribesAfterFailure() = runTest {
        val task = ModelTask()
        val counter = Counter()
        val received = mutableListOf<Int>()

        val isFailed = task.observe(
            values = values(counter, failures = 2),
            failure = "失敗",
        ) { received += it }

        assertFalse(isFailed)
        assertEquals(3, counter.attempts)
        assertEquals(listOf(1), received)
        assertEquals("", task.message)
        assertEquals(3000L, currentTime)
    }

    @Test
    fun stopsAtLimitWithNotice() = runTest {
        val task = ModelTask()
        val counter = Counter()

        val isFailed = task.observe(
            values = values(counter, failures = 10),
            failure = "失敗",
        ) {}

        assertTrue(isFailed)
        assertEquals(4, counter.attempts)
        assertEquals("失敗", task.message)
        assertEquals(7000L, currentTime)
    }

    @Test
    fun succeedsOnLastRetry() = runTest {
        val task = ModelTask()
        val counter = Counter()

        val isFailed = task.observe(
            values = values(counter, failures = 3),
            failure = "失敗",
        ) {}

        assertFalse(isFailed)
        assertEquals(4, counter.attempts)
        assertEquals("", task.message)
    }

    @Test
    fun reportsFailureUntilObservedAgain() = runTest {
        val task = ModelTask()
        val counter = Counter()
        val received = mutableListOf<Int>()

        val failed = task.observe(
            values = values(counter, failures = 4),
            failure = "失敗",
        ) { received += it }

        val failedAgain = task.observe(
            values = values(counter, failures = 4),
            failure = "失敗",
        ) { received += it }

        assertTrue(failed)
        assertFalse(failedAgain)
        assertEquals(listOf(1), received)
        assertEquals("失敗", task.message)
    }

    @Test
    fun countsEachNoticeAndKeepsItAfterSuccess() = runTest {
        val task = ModelTask()

        task.attempt(failure = "失敗") { throw IOException("failing for tests") }
        val first = task.count
        task.attempt(failure = "失敗") { 1 }
        val kept = task.message
        task.show("失敗")
        val second = task.count
        task.clear()

        assertEquals(1, first)
        assertEquals("失敗", kept)
        assertEquals(2, second)
        assertEquals("", task.message)
    }

    @Test
    fun stopsWhenFailingRightAfterEachValue() = runTest {
        val counter = Counter()
        val received = mutableListOf<Int>()

        val isFailed = ScreenObservation.retry(
            values = valueThenFailure(counter),
            retryDelays = listOf(Duration.ZERO, Duration.ZERO, Duration.ZERO),
        ) { received += it }

        assertTrue(isFailed)
        assertEquals(4, counter.attempts)
        assertEquals(listOf(1, 1, 1, 1), received)
    }

    @Test
    fun stopsWhenCancelled() = runTest {
        val task = ModelTask()
        val counter = Counter()

        val job = launch {
            task.observe(
                values = values(counter, failures = 10),
                failure = "失敗",
                retryDelays = listOf(60.seconds),
            ) {}
        }

        runCurrent()
        job.cancel()
        job.join()

        assertEquals(1, counter.attempts)
        assertEquals("", task.message)
    }

    @Test
    fun keepsEarlierMessageWhileObserving() = runTest {
        val task = ModelTask()
        task.show("保存できませんでした")

        task.observe(
            values = values(Counter(), failures = 0),
            failure = "失敗",
        ) {}

        assertEquals("保存できませんでした", task.message)
    }

    @Test
    fun sharesValuesAfterSourceRecovers() = runTest {
        val counter = Counter()
        val received = mutableListOf<Int>()

        val shared = ScreenObservation.share(
            values = values(counter, failures = 2),
            scope = backgroundScope,
            started = SharingStarted.WhileSubscribed(),
        )

        val isFailed = ScreenObservation.retry(values = shared.take(1)) { received += it }

        assertFalse(isFailed)
        assertEquals(3, counter.attempts)
        assertEquals(listOf(1), received)
    }

    @Test
    fun sharesFailureWithEachSubscriber() = runTest {
        val counter = Counter()
        val first = ModelTask()
        val second = ModelTask()

        val shared = ScreenObservation.share(
            values = values(counter, failures = 100),
            scope = backgroundScope,
            started = SharingStarted.WhileSubscribed(),
        )

        val other = launch { second.observe(values = shared, failure = "失敗") {} }
        val isFailed = first.observe(values = shared, failure = "失敗") {}
        other.join()

        assertTrue(isFailed)
        assertEquals("失敗", first.message)
        assertEquals("失敗", second.message)
        assertTrue(counter.attempts > 1)
    }

    private class Counter {
        var attempts = 0
    }

    private fun values(
        counter: Counter,
        failures: Int,
    ): Flow<Int> = flow {
        counter.attempts += 1

        if (counter.attempts <= failures) {
            throw IOException("failing for tests")
        }

        emit(1)
    }

    private fun valueThenFailure(counter: Counter): Flow<Int> = flow {
        counter.attempts += 1
        emit(1)
        throw IOException("failing for tests")
    }
}
