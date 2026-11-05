package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class RecurringScheduleTest {
    @RunWith(Parameterized::class)
    class FindsDatesInRange(
        private val fixture: DatesCase,
    ) {
        @Serializable
        data class DatesCase(
            val summary: String,
            val frequency: Recurring.Frequency,
            val month: Int? = null,
            val day: Int,
            val holidayShift: HolidayShift? = null,
            val startDate: LocalDate,
            val endDate: LocalDate? = null,
            val from: LocalDate,
            val through: LocalDate,
            val dates: List<LocalDate>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsDatesInRange() {
            val recurring = recurring(
                frequency = fixture.frequency,
                month = fixture.month,
                day = fixture.day,
                startDate = fixture.startDate,
                endDate = fixture.endDate,
            ).copy(holidayShift = fixture.holidayShift ?: HolidayShift.none)

            val dates = recurring.dates(
                from = fixture.from,
                through = fixture.through,
            )

            assertEquals(fixture.dates, dates)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<DatesCase> = CoreFixture.cases("recurring/recurring-dates.json", DatesCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class CreatesOnlyUnrecordedOccurrences(
        private val fixture: OccurrenceCase,
    ) {
        @Serializable
        data class OccurrenceCase(
            val summary: String,
            val day: Int,
            val holidayShift: HolidayShift? = null,
            val recorded: List<LocalDate>,
            val from: LocalDate,
            val through: LocalDate,
            val created: List<LocalDate>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun createsOnlyUnrecordedOccurrences() {
            val recurring = recurring(
                frequency = Recurring.Frequency.monthly,
                month = null,
                day = fixture.day,
                startDate = date("2026-01-01"),
                endDate = null,
            ).copy(holidayShift = fixture.holidayShift ?: HolidayShift.none)

            val entries = fixture.recorded.map { recorded ->
                Entry(
                    type = Entry.Kind.expense,
                    amount = 1000,
                    date = recorded,
                    categoryId = Identifier(),
                    walletId = Identifier(),
                    recurringId = recurring.id,
                    recurringDate = recorded,
                    createdAt = recurring.createdAt,
                    updatedAt = recurring.updatedAt,
                )
            }

            val created = recurring
                .occurrences(
                    from = fixture.from,
                    through = fixture.through,
                )
                .filter { occurrence ->
                    entries.none {
                        recurring.isRecorded(
                            by = it,
                            scheduled = occurrence.scheduled,
                        )
                    }
                }
                .map { it.scheduled }

            assertEquals(fixture.created, created)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<OccurrenceCase> =
                CoreFixture.cases("recurring/recurring-occurrence.json", OccurrenceCase.serializer())
        }
    }

    class Schedule {
        @Test
        fun continuesAfterGeneratedDate() {
            val today = date("2026-04-30")

            val recurring = recurring(
                frequency = Recurring.Frequency.monthly,
                month = null,
                day = 25,
                startDate = date("2026-01-01"),
                endDate = null,
            )

            val fresh = recurring.pendingOccurrences(today).map { it.date.toString() }

            val pending = recurring
                .copy(generatedUntil = date("2026-02-25"))
                .pendingOccurrences(today)
                .map { it.date.toString() }

            assertEquals(listOf("2026-01-25", "2026-02-25", "2026-03-25", "2026-04-25"), fresh)
            assertEquals(listOf("2026-03-25", "2026-04-25"), pending)
        }

        @Test
        fun findsNextDate() {
            val payday = date("2026-03-25")

            val recurring = recurring(
                frequency = Recurring.Frequency.monthly,
                month = null,
                day = 25,
                startDate = date("2026-01-01"),
                endDate = date("2026-06-30"),
            )

            val same = recurring.nextDate(onOrAfter = payday)
            val next = recurring.nextDate(onOrAfter = date("2026-03-26"))
            val none = recurring.nextDate(onOrAfter = date("2026-07-01"))

            assertEquals(payday, same)
            assertEquals("2026-04-25", next?.toString())
            assertNull(none)
        }

        @Test
        fun totalsTypeInRange() {
            val now = Instant.ofEpochSecond(1_791_000_000)

            val rent = Recurring(
                type = Entry.Kind.expense,
                amount = 78000,
                categoryId = Identifier(),
                walletId = Identifier(),
                frequency = Recurring.Frequency.monthly,
                day = 27,
                startDate = date("2026-01-01"),
                createdAt = now,
                updatedAt = now,
            )

            val insurance = rent.copy(
                amount = 12000,
                frequency = Recurring.Frequency.yearly,
                month = 4,
            )

            val salary = rent.copy(type = Entry.Kind.income)
            val recurrings = listOf(rent, insurance, salary)
            val range = date("2026-10-01")..date("2026-10-31")

            val expense = recurrings.total(
                of = Entry.Kind.expense,
                range = range,
            )

            val income = recurrings.total(
                of = Entry.Kind.income,
                range = range,
            )

            assertEquals(78000, expense)
            assertEquals(78000, income)
        }

    }
}

private fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))

private fun recurring(
    frequency: Recurring.Frequency,
    month: Int?,
    day: Int,
    startDate: LocalDate,
    endDate: LocalDate?,
): Recurring {
    val now = Instant.ofEpochSecond(1_791_000_000)

    return Recurring(
        type = Entry.Kind.expense,
        amount = 78000,
        categoryId = Identifier(),
        walletId = Identifier(),
        frequency = frequency,
        month = month,
        day = day,
        startDate = startDate,
        endDate = endDate,
        createdAt = now,
        updatedAt = now,
    )
}
