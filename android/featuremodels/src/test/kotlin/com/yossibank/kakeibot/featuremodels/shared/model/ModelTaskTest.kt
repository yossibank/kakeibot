package com.yossibank.kakeibot.featuremodels.shared.model

import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ModelTaskTest {
    @Test
    fun returnsValueAndMarksRunning() = runTest {
        val task = ModelTask()
        var whileRunning = false

        val value = task.attempt(failure = ModelTask.saveFailed) {
            whileRunning = task.isRunning
            3
        }

        assertEquals(3, value)
        assertTrue(whileRunning)
        assertFalse(task.isRunning)
    }

    @Test
    fun runsActionWhileRunning() = runTest {
        val task = ModelTask()
        var inner: Int? = null
        var count = 0

        task.attempt(failure = ModelTask.saveFailed) {
            count += 1
            inner = task.attempt(failure = ModelTask.saveFailed) {
                count += 1
                1
            }
        }

        assertEquals(2, count)
        assertEquals(1, inner)
        assertFalse(task.isRunning)
    }

    @Test
    fun stopsRunningAfterFailure() = runTest {
        val task = ModelTask()

        val failed = task.attempt<Int>(failure = ModelTask.saveFailed) {
            throw IllegalStateException("failure")
        }
        val value = task.attempt(failure = ModelTask.saveFailed) { 1 }

        assertNull(failed)
        assertFalse(task.isRunning)
        assertEquals(1, value)
        assertEquals(ModelTask.saveFailed, task.message)
    }
}
