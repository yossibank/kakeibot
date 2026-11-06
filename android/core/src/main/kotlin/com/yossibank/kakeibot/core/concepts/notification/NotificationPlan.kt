package com.yossibank.kakeibot.core.concepts.notification

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.dates
import com.yossibank.kakeibot.core.concepts.recurring.scheduledAmount
import com.yossibank.kakeibot.core.concepts.recurring.title
import com.yossibank.kakeibot.core.shared.Identifier
import kotlin.math.absoluteValue

object NotificationPlan {
    data class Shortage(
        val recurringId: Identifier<Recurring>,
        val date: LocalDate,
        val walletName: String,
        val amount: Long,
    )

    const val reminderDays = 30
    const val recurringDays = 31
    const val maxCount = 64

    fun notifications(
        today: LocalDate,
        reminderTime: ReminderTime?,
        recordedDates: Set<LocalDate>,
        recurrings: List<Recurring>,
        names: Map<Identifier<EntryCategory>, String>,
        shortages: List<Shortage> = emptyList(),
    ): List<PlannedNotification> {
        val reminders = reminderTime?.let { time ->
            reminders(
                today = today,
                time = time,
                recorded = recordedDates,
            )
        } ?: emptyList()

        val notices = recurrings.flatMap { recurring ->
            notices(
                of = recurring,
                today = today,
                time = reminderTime ?: ReminderTime.morning,
                names = names,
                shortages = shortages,
            )
        }

        val sorted = (reminders + notices).sortedWith(
            compareBy<PlannedNotification> { it.date }
                .thenBy { it.time }
                .thenBy { it.key },
        )

        return sorted.take(maxCount)
    }

    private fun reminders(
        today: LocalDate,
        time: ReminderTime,
        recorded: Set<LocalDate>,
    ): List<PlannedNotification> = (0 until reminderDays)
        .map { today.adding(days = it) }
        .filter { it !in recorded }
        .map { date ->
            val message = ReminderMessage(on = date.weekday)

            PlannedNotification(
                key = "reminder",
                date = date,
                time = time,
                title = message.title,
                body = message.body,
                route = PlannedNotification.Route.Entry(date),
            )
        }

    private fun notices(
        of: Recurring,
        today: LocalDate,
        time: ReminderTime,
        names: Map<Identifier<EntryCategory>, String>,
        shortages: List<Shortage>,
    ): List<PlannedNotification> {
        val daysBefore = of.remindDaysBefore ?: return emptyList()

        val category = of.categoryId?.let { names[it] }
        val name = of.title(categoryName = category) ?: "固定費"
        val start = today.adding(days = daysBefore)
        val span = recurringDays - 1
        val end = start.adding(days = span)
        val usesCardBill = of.closingDay != null

        return of
            .dates(
                from = start,
                through = end,
            )
            .map { date ->
                val amount = if (usesCardBill) null else of.scheduledAmount(paidOn = date).toLong()

                val shortage = shortages.firstOrNull { shortage ->
                    shortage.recurringId == of.id && shortage.date == date
                }

                val notifyDate = date.adding(days = -daysBefore)

                val text = body(
                    amount = amount,
                    on = date,
                    daysBefore = daysBefore,
                    shortage = shortage,
                )

                PlannedNotification(
                    key = "recurring-${of.id}",
                    date = notifyDate,
                    time = time,
                    title = name,
                    body = text,
                    route = PlannedNotification.Route.Recurring(of.id),
                )
            }
    }

    private fun body(
        amount: Long?,
        on: LocalDate,
        daysBefore: Int,
        shortage: Shortage?,
    ): String {
        if (amount == null) {
            val bill = if (daysBefore == 0) {
                "今日は引き落としの日です"
            } else {
                "${on.monthDayText} に引き落としがあります"
            }

            if (shortage == null) {
                return bill
            }

            val lack = "¥${grouped(shortage.amount)}"

            return "$bill。${shortage.walletName}が $lack 足りません"
        }

        val yen = "¥${grouped(amount)}"

        if (daysBefore == 0) {
            return "今日は $yen の日です"
        }

        return "${on.monthDayText} に $yen です"
    }

    private fun grouped(amount: Long): String {
        val digits = amount.absoluteValue.toString()
        val text = StringBuilder()

        for ((index, digit) in digits.withIndex()) {
            if (index > 0 && (digits.length - index) % 3 == 0) {
                text.append(',')
            }

            text.append(digit)
        }

        return if (amount < 0) "-$text" else text.toString()
    }
}
