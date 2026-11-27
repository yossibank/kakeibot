package com.yossibank.kakeibot.featuremodels.screens.main

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.notification.PlannedNotification
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.tabs.assets.model.AssetsModel
import com.yossibank.kakeibot.featuremodels.shared.model.ForegroundReturn
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.support.modelTest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

@OptIn(ExperimentalCoroutinesApi::class)
class MainModelTest {
    private val date = checkNotNull(LocalDate.parse("2026-10-15"))
    private val entry = MainModel.Sheet.Entry(editing = null, date = date)

    @Before
    fun setMain() {
        Dispatchers.setMain(StandardTestDispatcher())
    }

    @After
    fun resetMain() {
        Dispatchers.resetMain()
    }

    @Test
    fun opensHomeRouteWithoutWaiting() = runTest {
        val model = MainModel()
        model.state.select(MainModel.Tab.Records)
        var tabAfterRoute: MainModel.Tab? = null

        val route = model.perform { it.open(PlannedNotification.Route.Home) }
        val probe = model.perform { tabAfterRoute = it.state.tabs.current }

        route.join()
        probe.join()

        assertEquals(MainModel.Tab.Home, tabAfterRoute)
        assertNull(model.state.presented.sheet.current)
        assertEquals(setOf(MainModel.Tab.Home, MainModel.Tab.Records), model.state.tabs.visited)
        assertEquals(0, currentTime)
    }

    @Test
    fun opensEntryRouteOnHomeWithDate() = modelTest(today = "2026-10-17") { setup ->
        val model = MainModel()
        model.state.select(MainModel.Tab.Assets)

        model.open(PlannedNotification.Route.Entry(date = date))

        val sheet = model.state.presented.sheet.current as? MainModel.Sheet.Entry

        val entry = EntryModel(
            parts = setup.parts,
            today = setup.today,
            editing = sheet?.editing,
            date = sheet?.date ?: setup.today,
        )

        assertEquals(MainModel.Tab.Home, model.state.tabs.current)
        assertEquals(MainModel.Sheet.Entry(editing = null, date = date), sheet)
        assertEquals(date, entry.state.form.date)
        assertEquals(setup.today, entry.input.today)
    }

    @Test
    fun opensRecurringRouteOnCurrentTab() = runTest {
        val model = MainModel()
        val id = Identifier<Recurring>()
        model.state.select(MainModel.Tab.Review)

        model.open(PlannedNotification.Route.Recurring(id = id))
        val first = model.state.presented.sheet.current
        model.open(PlannedNotification.Route.Recurring(id = id))

        assertEquals(MainModel.Tab.Review, model.state.tabs.current)
        assertEquals(MainModel.Sheet.Settings(recurring = id, round = 1), first)
        assertEquals(
            MainModel.Sheet.Settings(recurring = id, round = 2),
            model.state.presented.sheet.current,
        )
    }

    @Test
    fun closesOpenSheetBeforeOpeningRoute() = runTest {
        val model = MainModel(sheet = MainModel.Sheet.Settings())
        model.state.select(MainModel.Tab.Records)
        var whileWaiting: Seen? = null

        val route = model.perform { it.open(PlannedNotification.Route.Entry(date = date)) }
        val probe = model.perform { whileWaiting = seen(it) }

        route.join()
        probe.join()

        assertEquals(Seen(sheet = null, tab = MainModel.Tab.Records), whileWaiting)
        assertEquals(Seen(sheet = entry, tab = MainModel.Tab.Home), seen(model))
        assertEquals(MainModel.sheetCloseDelay.inWholeMilliseconds, currentTime)
    }

    @Test
    fun opensSecondRouteWhileFirstWaits() = runTest {
        val model = MainModel(sheet = MainModel.Sheet.Settings())
        val id = Identifier<Recurring>()
        model.state.select(MainModel.Tab.Records)
        var afterSecond: Seen? = null

        val first = model.perform { it.open(PlannedNotification.Route.Entry(date = date)) }

        val second = model.perform {
            it.open(PlannedNotification.Route.Recurring(id = id))
            afterSecond = seen(it)
        }

        first.join()
        second.join()

        val recurring = MainModel.Sheet.Settings(recurring = id, round = 1)

        assertEquals(Seen(sheet = recurring, tab = MainModel.Tab.Records), afterSecond)
        assertEquals(Seen(sheet = entry, tab = MainModel.Tab.Home), seen(model))
    }

    @Test
    fun restartsObservationWhenReturningFromBackground() {
        val model = MainModel()

        model.state.changeScene(to = ForegroundReturn.Phase.Inactive)
        model.state.changeScene(to = ForegroundReturn.Phase.Active)
        val afterInactive = model.state.observationRound
        model.state.changeScene(to = ForegroundReturn.Phase.Background)
        model.state.changeScene(to = ForegroundReturn.Phase.Inactive)
        model.state.changeScene(to = ForegroundReturn.Phase.Active)
        val afterBackground = model.state.observationRound
        model.state.changeScene(to = ForegroundReturn.Phase.Active)

        assertEquals(0, afterInactive)
        assertEquals(1, afterBackground)
        assertEquals(1, model.state.observationRound)
    }

    @Test
    fun restartsObservationOnRetry() = modelTest(today = "2026-10-15") { setup ->
        val model = MainModel()

        val assets = AssetsModel(
            parts = setup.parts(entryList = emptyFlow()),
            today = date,
            round = model.state.observation,
        )

        model.state.restartObservation()
        val afterRestart = model.state.observationRound
        assets.retry()

        assertEquals(1, afterRestart)
        assertEquals(2, model.state.observationRound)
    }

    @Test
    fun advancesNoticeRoundToHideTabNotices() = runTest {
        val model = MainModel()

        model.state.hideTabNotices()

        assertEquals(1, model.state.notices.round)
        assertEquals(0, model.state.observationRound)
    }

    @Test
    fun keepsTabsAndSheetWhenRestored() {
        val id = Identifier<Entry>()

        val model = MainModel()
        model.state.select(MainModel.Tab.Review)
        model.openEntry(editing = id)

        val saved = model.saved()
        val restored = MainModel.restore(saved)
        val dated = MainModel(sheet = entry)

        restored.state.select(MainModel.Tab.Assets)

        assertEquals(MainModel.Tab.Assets, restored.state.tabs.current)
        assertEquals(
            MainModel.Tab.entries.toSet() - MainModel.Tab.Records,
            restored.state.tabs.visited,
        )
        assertEquals(MainModel.Sheet.Entry(editing = id), restored.state.presented.sheet.current)
        assertEquals(entry, MainModel.restore(dated.saved()).state.presented.sheet.current)
    }
}

private data class Seen(
    val sheet: MainModel.Sheet?,
    val tab: MainModel.Tab,
)

private fun seen(model: MainModel): Seen = Seen(
    sheet = model.state.presented.sheet.current,
    tab = model.state.tabs.current,
)
