package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.featuremodels.screens.settings.menu.SettingsMenuModel
import com.yossibank.kakeibot.featuremodels.support.modelTest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class ScreenPerformingTest {
    @Before
    fun setMain() {
        Dispatchers.setMain(StandardTestDispatcher())
    }

    @After
    fun resetMain() {
        Dispatchers.resetMain()
    }

    @Test
    fun runsModelWorkUntilItEnds() = modelTest(today = "2026-10-17") { setup ->
        val model = SettingsMenuModel(parts = setup.parts)

        model.perform { it.loadFold(it.input.monthStartHint) }.join()

        assertEquals(false, model.input.monthStartHint.isClosed)
    }

    @Test
    fun startsWorkAfterCallerReturns() = runTest {
        val steps = Steps()

        val work = steps.perform { it.values.add(1) }
        val valuesAtReturn = steps.values.toList()

        work.join()

        assertTrue(valuesAtReturn.isEmpty())
        assertEquals(listOf(1), steps.values)
    }

    @Test
    fun startsWorksInCalledOrder() = runTest {
        val steps = Steps()

        val first = steps.perform { it.values.add(1) }
        val second = steps.perform { it.values.add(2) }

        first.join()
        second.join()

        assertEquals(listOf(1, 2), steps.values)
    }
}

private class Steps : ScreenPerforming {
    val values = mutableListOf<Int>()
}
