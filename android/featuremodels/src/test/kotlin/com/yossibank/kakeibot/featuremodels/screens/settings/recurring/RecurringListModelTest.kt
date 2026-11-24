package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecurringListModelTest {
    @Test
    fun listsWithScheduleAndNextDate() = modelTest(today = "2026-10-17") { setup ->
        setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")
        val model = setup.observedModel()
        val row = model.output.rows.first()

        assertEquals("家賃", row.title)
        assertEquals("毎月 27 日", row.schedule)
        assertEquals("財布", row.place)
        assertEquals(78000, row.amount)
        assertEquals("2026-10-27", row.next.toString())
        assertNull(row.closing)
        assertEquals(78000L, model.output.monthTotal)

        model.state.type = Entry.Kind.income

        assertTrue(model.output.rows.isEmpty())
        assertEquals(0L, model.output.monthTotal)
        assertEquals("給料や年金などを足すと、ここに並びます", model.output.emptyText)
    }

    @Test
    fun totalsMonthFromMonthStartDay() = modelTest(today = "2026-10-17") { setup ->
        setup.database.setSetting(
            key = SettingKey.monthStartDay,
            to = checkNotNull(MonthStartDay.of(day = 25)),
        )
        setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")
        val model = setup.observedModel()
        ModelWait.until { model.input.monthStartDay.day == 25 }

        assertEquals(0L, model.output.monthTotal)
    }

    @Test
    fun hidesAndShowsRecurring() = modelTest(today = "2026-10-17") { setup ->
        val saved = setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")
        val model = setup.observedModel()

        val hidden = model.hide(saved.id)
        ModelWait.until { model.output.hiddenRows.isNotEmpty() }
        val shownWhileHidden = model.output.rows.size
        val totalWhileHidden = model.output.monthTotal

        val shown = model.show(saved.id)
        ModelWait.until { model.output.rows.isNotEmpty() }

        assertTrue(hidden)
        assertTrue(shown)
        assertEquals(0, shownWhileHidden)
        assertEquals(0L, totalWhileHidden)
        assertTrue(model.output.hiddenRows.isEmpty())
        assertEquals("家賃", model.output.rows.first().title)
    }

    @Test
    fun savesMovedOrder() = modelTest(today = "2026-10-17") { setup ->
        setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")
        setup.saveRecurring(amount = 1000, day = 5, memo = "サブスク")
        val model = setup.observedModel(count = 2)
        val second = model.output.rows[1].id

        model.move(id = second, to = 0)
        val moving = model.output.rows.map { it.title }
        model.finishMoving()
        ModelWait.until { model.output.visible.first().id == second }

        assertEquals(listOf("サブスク", "家賃"), moving)
        assertNull(model.state.movingOrder)
        assertEquals(listOf("サブスク", "家賃"), setup.database.recurrings().map { it.memo })
    }

    @Test
    fun deletesAndRestoresRecurring() = modelTest(today = "2026-10-17") { setup ->
        val saved = setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")
        val model = setup.observedModel()

        val deletion = assertNotNull(model.delete(saved.id))
        ModelWait.until { model.output.rows.isEmpty() }
        model.restore(deletion)
        ModelWait.until { model.output.rows.isNotEmpty() }

        assertEquals(listOf(saved.id), setup.database.recurrings().map { it.id })
    }

    @Test
    fun deletesOnlyHiddenRecurrings() = modelTest(today = "2026-10-17") { setup ->
        val rent = setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")
        setup.saveRecurring(amount = 1000, day = 5, memo = "サブスク")
        val model = setup.observedModel(count = 2)
        val none = model.deleteHidden()

        model.hide(rent.id)
        ModelWait.until { model.output.hidden.isNotEmpty() }
        val deletion = model.deleteHidden()
        ModelWait.until { model.output.hidden.isEmpty() }

        assertNull(none)
        assertNotNull(deletion)
        assertEquals(
            listOf("サブスク"),
            setup.database.recurrings(includingHidden = true).map {
                it.memo
            },
        )
    }

    @Test
    fun startsFromFirstPeriodOnLaterDay() = modelTest(today = "2026-10-17") { setup ->
        setup.saveRecurring(amount = 78000, day = 5, start = date("2026-09-01"), memo = "家賃")
        val model = setup.observedModel()

        assertEquals("2026-11-05", model.output.rows.first().next.toString())
    }

    private suspend fun ModelTestSetup.observedModel(count: Int = 1): RecurringListModel {
        val model = RecurringListModel(
            database = database,
            clock = ScreenClock.fixed(now),
            entryList = database.entryListUpdates(),
            today = today,
        )

        scope.launch { model.observe() }
        ModelWait.until { model.output.rows.size == count }

        return model
    }
}
