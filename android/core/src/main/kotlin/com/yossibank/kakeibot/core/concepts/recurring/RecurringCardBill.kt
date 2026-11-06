package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

val Recurring.Companion.billChoiceCount: Int
    get() = 3

val Recurring.Companion.billShiftTitles: List<String>
    get() = listOf(
        "いつもどおり",
        "次に回す",
        "2 回先",
    )

fun Recurring.Companion.billText(paidOn: LocalDate): String = "${paidOn.month}/${paidOn.day}払い"

fun Recurring.Companion.clampedBillShift(shift: Int): Int = shift.coerceIn(0, billChoiceCount - 1)

fun Recurring.billingPeriod(paidOn: LocalDate): ClosedRange<LocalDate>? {
    val closingDay = closingDay ?: return null
    val scheduled = scheduledDate(of = paidOn)

    val closingMonth = if (day > closingDay) {
        scheduled.yearMonth
    } else {
        scheduled.yearMonth.adding(months = -1)
    }

    val closing = LocalDate.ofClamped(
        yearMonth = closingMonth,
        clampedDay = closingDay,
    )

    val previous = LocalDate.ofClamped(
        yearMonth = closingMonth.adding(months = -1),
        clampedDay = closingDay,
    )

    return previous.adding(days = 1)..closing
}

fun Recurring.amount(
    paidOn: LocalDate,
    entries: List<Entry>,
): Long {
    val billed = billedEntries(
        paidOn = paidOn,
        entries = entries,
    ) ?: return scheduledAmount(paidOn = paidOn).toLong()

    val used = billed.sumOf { usage(it) }

    return maxOf(used, 0L)
}

fun Recurring.billedEntries(
    paidOn: LocalDate,
    entries: List<Entry>,
): List<Entry>? {
    val period = billingPeriod(paidOn) ?: return null
    val card = toWalletId ?: return null

    return entries
        .filter { it.walletId == card }
        .filter {
            isBilled(
                entry = it,
                paidOn = paidOn,
                period = period,
            )
        }
}

fun Recurring.billMonth(
    used: LocalDate,
    shift: Int,
): YearMonth? {
    val dates = billDates(
        used = used,
        count = Recurring.billChoiceCount,
    )

    if (shift <= 0 || shift !in dates.indices) {
        return null
    }

    return occurrenceMonth(of = dates[shift])
}

fun Recurring.billDate(
    used: LocalDate,
    month: YearMonth,
): LocalDate? = billDates(
    used = used,
    count = Recurring.billChoiceCount,
).firstOrNull { occurrenceMonth(of = it) == month }

fun Recurring.billDates(
    used: LocalDate,
    count: Int,
): List<LocalDate> {
    if (closingDay == null) {
        return emptyList()
    }

    val schedule = copy(startDate = minOf(startDate, used))
    val dates = mutableListOf<LocalDate>()
    var cursor = used

    while (dates.size < count) {
        val next = schedule.nextDate(onOrAfter = cursor) ?: break
        val closing = billingPeriod(next)?.endInclusive ?: next

        if (dates.isNotEmpty() || used <= closing) {
            dates += next
        }

        cursor = next.adding(days = 1)
    }

    return dates
}

fun List<Recurring>.cardBill(paidBy: Identifier<Wallet>?): Recurring? = firstOrNull { recurring ->
    recurring.type == Entry.Kind.transfer &&
        recurring.closingDay != null &&
        recurring.toWalletId == paidBy
}

private fun usage(entry: Entry): Long = when (entry.type) {
    Entry.Kind.expense,
    Entry.Kind.transfer,
    -> entry.amount.toLong()

    Entry.Kind.income -> -entry.amount.toLong()
}

private fun Recurring.isBilled(
    entry: Entry,
    paidOn: LocalDate,
    period: ClosedRange<LocalDate>,
): Boolean {
    val month = entry.billMonth ?: return entry.date in period

    return month == occurrenceMonth(of = paidOn)
}
