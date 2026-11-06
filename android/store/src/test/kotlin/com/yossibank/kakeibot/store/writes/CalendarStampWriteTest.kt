package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertShelfIfEmpty
import com.yossibank.kakeibot.store.queries.methods.iconShelf
import com.yossibank.kakeibot.store.queries.methods.stampCalendar
import com.yossibank.kakeibot.store.writes.methods.removeStamp
import com.yossibank.kakeibot.store.writes.methods.setShelfIconHidden
import com.yossibank.kakeibot.store.writes.methods.stamp
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class CalendarStampWriteTest {
    @Test
    fun stampsAndReplacesOnTheSameDay() = runTest {
        val setup = Setup.make()
        val star = setup.shelf[0]
        val party = setup.shelf[1]

        setup.database.stamp(
            star,
            on = setup.day,
            at = setup.now,
        )

        val first = setup.database.stampCalendar()

        setup.database.stamp(
            party,
            on = setup.day,
            at = setup.now,
        )

        val replaced = setup.database.stampCalendar()

        assertEquals(1, first.stamps.size)
        assertEquals(Icon.Glyph.star, first.icon(on = setup.day)?.glyph)
        assertEquals(1, replaced.stamps.size)
        assertEquals(Icon.Glyph.party, replaced.icon(on = setup.day)?.glyph)

        setup.database.close()
    }

    @Test
    fun removesStamp() = runTest {
        val setup = Setup.make()
        val star = setup.shelf[0]
        val nextDay = setup.day.adding(days = 1)

        setup.database.stamp(
            star,
            on = setup.day,
            at = setup.now,
        )

        setup.database.stamp(
            star,
            on = nextDay,
            at = setup.now,
        )

        setup.database.removeStamp(on = setup.day)
        val calendar = setup.database.stampCalendar()

        assertNull(calendar.stamps[setup.day])
        assertEquals(Icon.Glyph.star, calendar.icon(on = nextDay)?.glyph)

        setup.database.close()
    }

    @Test
    fun keepsStampWhenItsStampIsHidden() = runTest {
        val setup = Setup.make()
        val shelf = setup.database.iconShelf()
        val first = assertNotNull(shelf.shelfIcons.firstOrNull())

        setup.database.stamp(
            first.iconId,
            on = setup.day,
            at = setup.now,
        )

        setup.database.setShelfIconHidden(
            first.id,
            isHidden = true,
            at = setup.now,
        )

        val calendar = setup.database.stampCalendar()

        assertEquals(Icon.Glyph.star, calendar.icon(on = setup.day)?.glyph)

        setup.database.close()
    }

    @Test
    fun talliesStampsInRange() = runTest {
        val setup = Setup.make()
        val star = setup.shelf[0]
        val party = setup.shelf[1]
        val cake = setup.shelf[3]
        val start = setup.day
        val end = start.adding(days = 6)

        val stamps = listOf(
            star to start,
            party to start.adding(days = 1),
            star to start.adding(days = 2),
            cake to start.adding(days = 3),
            star to end.adding(days = 1),
        )

        for ((icon, date) in stamps) {
            setup.database.stamp(
                icon,
                on = date,
                at = setup.now,
            )
        }

        val calendar = setup.database.stampCalendar()
        val tallies = calendar.tallies(start..end)

        assertEquals(
            listOf(
                Icon.Glyph.star,
                Icon.Glyph.cake,
                Icon.Glyph.party,
            ),
            tallies.map { it.icon.glyph },
        )

        assertEquals(listOf(2, 1, 1), tallies.map { it.count })

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val day: LocalDate,
        val shelf: List<Identifier<Icon>>,
    ) {
        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)
                val day = assertNotNull(LocalDate.parse("2026-10-19"))

                database.insertShelfIfEmpty(now)

                return Setup(
                    database = database,
                    now = now,
                    day = day,
                    shelf = database.iconShelf().shelfIcons.map { it.iconId },
                )
            }
        }
    }
}
