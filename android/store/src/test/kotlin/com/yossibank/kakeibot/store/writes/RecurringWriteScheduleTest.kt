package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.support.execute
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class RecurringWriteScheduleTest {
    @Test
    fun generatesOnShiftedDate() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val today = assertNotNull(LocalDate.parse("2026-04-30"))
        setup.shiftHoliday(to = HolidayShift.next)

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val entries = setup.database.snapshot().entries
        val dates = entries.map { it.date }.sorted().map { it.toString() }
        val scheduled = entries.mapNotNull { it.recurringDate }.sorted().map { it.toString() }

        assertEquals(
            listOf(
                "2026-01-26",
                "2026-02-25",
                "2026-03-25",
                "2026-04-27",
            ),
            dates,
        )

        assertEquals(
            listOf(
                "2026-01-25",
                "2026-02-25",
                "2026-03-25",
                "2026-04-25",
            ),
            scheduled,
        )

        setup.database.close()
    }

    @Test
    fun keepsOneEntryAfterChangingShift() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val saturday = assertNotNull(LocalDate.parse("2026-04-25"))
        val may = assertNotNull(LocalDate.parse("2026-05-31"))

        setup.database.generateRecurringEntries(
            through = saturday,
            at = setup.now,
        )

        setup.shiftHoliday(to = HolidayShift.next)

        setup.database.generateRecurringEntries(
            through = may,
            at = setup.now,
        )

        assertEquals(
            listOf(
                "2026-01-25",
                "2026-02-25",
                "2026-03-25",
                "2026-04-25",
                "2026-05-25",
            ),
            setup.scheduledDates(),
        )

        setup.database.close()
    }

    @Test
    fun keepsOneEntryAfterChangingDay() = runTest {
        for (day in listOf(20, 12)) {
            val setup = RecurringWriteTest.Setup.make()
            val first = assertNotNull(LocalDate.parse("2026-03-10"))
            val last = assertNotNull(LocalDate.parse("2026-03-31"))

            setup.database.generateRecurringEntries(
                through = first,
                at = setup.now,
            )

            setup.changeDay(to = day)

            setup.database.generateRecurringEntries(
                through = last,
                at = setup.now,
            )

            assertEquals(
                listOf(
                    "2026-01-25",
                    "2026-02-25",
                    "2026-03-$day",
                ),
                setup.scheduledDates(),
            )

            setup.database.close()
        }
    }

    @Test
    fun generatesPastEntriesWhenStartMovesEarlier() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val today = assertNotNull(LocalDate.parse("2026-03-31"))
        val earlier = assertNotNull(LocalDate.parse("2025-11-01"))

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val recurring = assertNotNull(setup.database.snapshot().recurrings.firstOrNull())
        val draft = RecurringDraft(recurring).copy(startDate = earlier)

        setup.database.saveRecurring(
            draft,
            editing = recurring.id,
            today = today,
            at = setup.now,
        )

        assertEquals(
            listOf(
                "2025-11-25",
                "2025-12-25",
                "2026-01-25",
                "2026-02-25",
                "2026-03-25",
            ),
            setup.scheduledDates(),
        )

        setup.database.close()
    }

    @Test
    fun createsNextOccurrenceAfterDroppingShift() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val paid = assertNotNull(LocalDate.parse("2027-03-01"))
        val end = assertNotNull(LocalDate.parse("2027-03-31"))

        setup.change(
            day = 27,
            shift = HolidayShift.next,
        )

        setup.database.generateRecurringEntries(
            through = paid,
            at = setup.now,
        )

        setup.change(
            day = 27,
            shift = HolidayShift.none,
        )

        setup.database.generateRecurringEntries(
            through = end,
            at = setup.now,
        )

        assertEquals(
            listOf("2027-02-27", "2027-03-27"),
            setup.scheduledDates().filter { it >= "2027-02-01" },
        )

        setup.database.close()
    }

    @Test
    fun createsNextOccurrenceAfterChangingDay() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val paid = assertNotNull(LocalDate.parse("2027-03-01"))
        val end = assertNotNull(LocalDate.parse("2027-03-31"))

        setup.change(
            day = 27,
            shift = HolidayShift.next,
        )

        setup.database.generateRecurringEntries(
            through = paid,
            at = setup.now,
        )

        setup.change(
            day = 20,
            shift = HolidayShift.next,
        )

        setup.database.generateRecurringEntries(
            through = end,
            at = setup.now,
        )

        assertEquals(
            listOf("2027-02-27", "2027-03-20"),
            setup.scheduledDates().filter { it >= "2027-02-01" },
        )

        setup.database.close()
    }

    @Test
    fun createsNextOccurrenceAfterYearEndShift() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val shifted = assertNotNull(LocalDate.parse("2027-01-04"))
        val end = assertNotNull(LocalDate.parse("2027-01-31"))

        setup.change(
            day = 31,
            shift = HolidayShift.next,
        )

        setup.database.generateRecurringEntries(
            through = shifted,
            at = setup.now,
        )

        setup.change(
            day = 31,
            shift = HolidayShift.none,
        )

        setup.database.generateRecurringEntries(
            through = end,
            at = setup.now,
        )

        assertEquals(
            listOf("2026-12-31", "2027-01-31"),
            setup.scheduledDates().filter { it >= "2026-12-01" },
        )

        setup.database.close()
    }

    @Test
    fun keepsDeletedOccurrenceWhenStartMovesEarlier() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val today = assertNotNull(LocalDate.parse("2026-03-31"))
        val earlier = assertNotNull(LocalDate.parse("2025-11-01"))

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        setup.database.execute("DELETE FROM entry WHERE recurring_date = '2026-02-25'")

        val recurring = assertNotNull(setup.database.snapshot().recurrings.firstOrNull())

        val draft = RecurringDraft(recurring).copy(
            startDate = earlier,
            day = 20,
        )

        setup.database.saveRecurring(
            draft,
            editing = recurring.id,
            today = today,
            at = setup.now,
        )

        assertEquals(
            listOf(
                "2025-11-20",
                "2025-12-20",
                "2026-01-25",
                "2026-03-25",
            ),
            setup.scheduledDates(),
        )

        setup.database.close()
    }

    @Test
    fun pausesWhileHiddenWithoutBackfill() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val january = assertNotNull(LocalDate.parse("2026-01-31"))
        val february = assertNotNull(LocalDate.parse("2026-02-01"))
        val april = assertNotNull(LocalDate.parse("2026-04-30"))
        val may = assertNotNull(LocalDate.parse("2026-05-25"))

        setup.database.generateRecurringEntries(
            through = january,
            at = setup.now,
        )

        val recurring = assertNotNull(setup.database.snapshot().recurrings.firstOrNull())

        setup.database.setRecurringHidden(
            recurring.id,
            isHidden = true,
            today = february,
            at = setup.now,
        )

        setup.database.generateRecurringEntries(
            through = april,
            at = setup.now,
        )

        val shownWhileHidden = setup.database.recurrings()
        val allWhileHidden = setup.database.recurrings(includingHidden = true)

        setup.database.setRecurringHidden(
            recurring.id,
            isHidden = false,
            today = may,
            at = setup.now,
        )

        assertTrue(shownWhileHidden.isEmpty())
        assertEquals(1, allWhileHidden.size)
        assertEquals(listOf("2026-01-25", "2026-05-25"), setup.scheduledDates())

        setup.database.close()
    }
}

private suspend fun RecurringWriteTest.Setup.scheduledDates(): List<String> = database
    .snapshot()
    .entries
    .mapNotNull { it.recurringDate }
    .sorted()
    .map { it.toString() }
