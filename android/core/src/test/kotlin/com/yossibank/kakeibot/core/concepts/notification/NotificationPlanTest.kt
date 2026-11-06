package com.yossibank.kakeibot.core.concepts.notification

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.net.URI
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class NotificationPlanTest {
    @RunWith(Parameterized::class)
    class PlansNotifications(
        private val fixture: PlanCase,
    ) {
        @Serializable
        data class PlanCase(
            val summary: String,
            val today: LocalDate,
            val reminderTime: ReminderTime?,
            val recorded: List<LocalDate>,
            val recurrings: List<RecurringRow>,
            val notifications: List<Expected>,
        ) {
            override fun toString(): String = summary
        }

        @Serializable
        data class RecurringRow(
            val name: String,
            val amount: Int,
            val frequency: Recurring.Frequency,
            val month: Int? = null,
            val day: Int,
            val closingDay: Int? = null,
            val startDate: LocalDate,
            val endDate: LocalDate? = null,
            val remindDaysBefore: Int? = null,
            val shortage: ShortageRow? = null,
        )

        @Serializable
        data class ShortageRow(
            val date: LocalDate,
            val wallet: String,
            val amount: Int,
        )

        @Serializable
        data class Expected(
            val date: LocalDate,
            val time: ReminderTime,
            val title: String,
            val body: String,
        )

        @Test
        fun plansNotifications() {
            val now = Instant.ofEpochSecond(1_791_000_000)

            val recurrings = fixture.recurrings.map { row ->
                val isBill = row.closingDay != null

                Recurring(
                    type = if (isBill) Entry.Kind.transfer else Entry.Kind.expense,
                    amount = row.amount,
                    categoryId = if (isBill) null else Identifier(),
                    walletId = Identifier(),
                    toWalletId = if (isBill) Identifier() else null,
                    memo = row.name,
                    frequency = row.frequency,
                    month = row.month,
                    day = row.day,
                    closingDay = row.closingDay,
                    startDate = row.startDate,
                    endDate = row.endDate,
                    remindDaysBefore = row.remindDaysBefore,
                    createdAt = now,
                    updatedAt = now,
                )
            }

            val shortages = fixture.recurrings.zip(recurrings).mapNotNull { (row, recurring) ->
                row.shortage?.let { shortage ->
                    NotificationPlan.Shortage(
                        recurringId = recurring.id,
                        date = shortage.date,
                        walletName = shortage.wallet,
                        amount = shortage.amount.toLong(),
                    )
                }
            }

            val notifications = NotificationPlan.notifications(
                today = fixture.today,
                reminderTime = fixture.reminderTime,
                recordedDates = fixture.recorded.toSet(),
                recurrings = recurrings,
                names = emptyMap(),
                shortages = shortages,
            )

            val rows = notifications.map { notification ->
                Expected(
                    date = notification.date,
                    time = notification.time,
                    title = notification.title,
                    body = notification.body,
                )
            }

            assertEquals(fixture.notifications, rows)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<PlanCase> =
                CoreFixture.cases("notification/notification-plan.json", PlanCase.serializer())
        }
    }

    class Plan {
        @Test
        fun keepsEarliestSixtyFour() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val today = date("2026-10-17")
            val time = assertNotNull(ReminderTime.parse("21:00"))
            val last = date("2026-11-09")

            val recurrings = (0 until 40).map { index ->
                Recurring(
                    type = Entry.Kind.expense,
                    amount = 1000,
                    categoryId = Identifier(),
                    walletId = Identifier(),
                    memo = "固定費$index",
                    frequency = Recurring.Frequency.monthly,
                    day = 5,
                    startDate = today,
                    remindDaysBefore = 0,
                    createdAt = now,
                    updatedAt = now,
                )
            }

            val notifications = NotificationPlan.notifications(
                today = today,
                reminderTime = time,
                recordedDates = emptySet(),
                recurrings = recurrings,
                names = emptyMap(),
            )

            assertEquals(64, NotificationPlan.maxCount)
            assertEquals(64, notifications.size)
            assertEquals(today, notifications.firstOrNull()?.date)
            assertEquals(last, notifications.lastOrNull()?.date)
            assertEquals(notifications.map { it.date }.sorted(), notifications.map { it.date })
        }

        @Test
        fun writesShortageBeyondIntRange() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val today = date("2026-10-17")
            val time = assertNotNull(ReminderTime.parse("21:00"))

            val bill = Recurring(
                type = Entry.Kind.transfer,
                amount = 0,
                categoryId = null,
                walletId = Identifier(),
                toWalletId = Identifier(),
                frequency = Recurring.Frequency.monthly,
                day = 5,
                closingDay = 15,
                startDate = today,
                remindDaysBefore = 0,
                createdAt = now,
                updatedAt = now,
            )

            val shortage = NotificationPlan.Shortage(
                recurringId = bill.id,
                date = date("2026-11-05"),
                walletName = "銀行",
                amount = 3_000_000_000L,
            )

            val notifications = NotificationPlan.notifications(
                today = today,
                reminderTime = time,
                recordedDates = emptySet(),
                recurrings = listOf(bill),
                names = emptyMap(),
                shortages = listOf(shortage),
            )

            val body = notifications.single { it.route is PlannedNotification.Route.Recurring && it.date == date("2026-11-05") }.body

            assertEquals("今日は引き落としの日です。銀行が ¥3,000,000,000 足りません", body)
        }

        @Test
        fun readsAndWritesTime() {
            val time = assertNotNull(ReminderTime.parse("07:05"))

            assertEquals(7, time.hour)
            assertEquals(5, time.minute)
            assertEquals("07:05", time.toString())
            assertNull(ReminderTime.parse("7:05"))
            assertNull(ReminderTime.parse("24:00"))
        }

        @Test
        fun readsAndWritesLink() {
            val date = date("2026-10-18")
            val id = Identifier<Recurring>()
            val entry = PlannedNotification.Route.Entry(date)
            val recurring = PlannedNotification.Route.Recurring(id)
            val template = PlannedNotification.Route.Template(Identifier<EntryTemplate>())

            assertEquals("entry/2026-10-18", entry.link)
            assertEquals(entry, PlannedNotification.Route.of(link = entry.link))
            assertEquals(recurring, PlannedNotification.Route.of(link = recurring.link))
            assertEquals(template, PlannedNotification.Route.of(link = template.link))
            assertEquals(PlannedNotification.Route.NewTemplate, PlannedNotification.Route.of(link = "new-template"))
            assertNull(PlannedNotification.Route.of(link = "template/x"))
            assertNull(PlannedNotification.Route.of(link = "entry/2026-13-01"))
            assertNull(PlannedNotification.Route.of(link = "budget/1"))
            assertNull(PlannedNotification.Route.of(link = "entry"))
        }

        @Test
        fun readsAndWritesURL() {
            val date = date("2026-10-18")
            val home = PlannedNotification.Route.Home
            val entry = PlannedNotification.Route.Entry(date)
            val homeURL = assertNotNull(home.url)
            val entryURL = assertNotNull(entry.url)
            val newTemplateURL = assertNotNull(PlannedNotification.Route.NewTemplate.url)
            val other = URI("https://example.com/home")

            assertEquals("kakeibot://home", homeURL.toString())
            assertEquals("kakeibot://entry/2026-10-18", entryURL.toString())
            assertEquals(home, PlannedNotification.Route.of(url = homeURL))
            assertEquals(entry, PlannedNotification.Route.of(url = entryURL))
            assertEquals("kakeibot://new-template", newTemplateURL.toString())
            assertEquals(PlannedNotification.Route.NewTemplate, PlannedNotification.Route.of(url = newTemplateURL))
            assertNull(PlannedNotification.Route.of(url = other))
        }
    }
}

private fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))
