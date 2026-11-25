package com.yossibank.kakeibot.featuremodels.shared.model

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class SharedObservationTest {
    @Before
    fun setMain() {
        Dispatchers.setMain(StandardTestDispatcher())
    }

    @After
    fun resetMain() {
        Dispatchers.resetMain()
    }

    @Test
    fun sharesOneSourceBetweenSubscribers() = runTest {
        var started = 0

        val shared = SharedObservation(
            values = flow {
                started += 1
                emit(1)
                awaitCancellation()
            },
            started = SharingStarted.WhileSubscribed(),
        )

        val first = async { shared.values.first() }
        val second = async { shared.values.first() }
        val received = listOf(first.await(), second.await())
        shared.stop()

        assertEquals(listOf(1, 1), received)
        assertEquals(1, started)
    }

    @Test
    fun stopsSourceWhenStopped() = runTest {
        var isStopped = false
        val received = mutableListOf<Int>()

        val shared = SharedObservation(
            values = flow {
                emit(1)

                try {
                    awaitCancellation()
                } finally {
                    isStopped = true
                }
            },
            started = SharingStarted.WhileSubscribed(),
        )

        val subscriber = launch { shared.values.collect { received += it } }
        runCurrent()
        val isStoppedWhileShared = isStopped
        shared.stop()
        runCurrent()
        subscriber.cancel()

        assertEquals(listOf(1), received)
        assertFalse(isStoppedWhileShared)
        assertTrue(isStopped)
    }
}
