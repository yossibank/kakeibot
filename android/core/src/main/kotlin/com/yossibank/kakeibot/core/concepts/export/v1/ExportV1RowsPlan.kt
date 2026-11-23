package com.yossibank.kakeibot.core.concepts.export.v1

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.core.concepts.icon.CalendarStamp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.concepts.receipt.ItemName
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.clampedBillShift
import com.yossibank.kakeibot.core.concepts.reward.RewardGoal
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.core.concepts.theme.Theme
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.InstantSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonObjectBuilder
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.time.Instant

internal fun Budget.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("categoryId", categoryId?.toString())
    put("fromMonth", fromMonth.toString())
    put("amount", amount)
}

internal fun ExportRow.budget(): Budget = Budget(
    id = id("id"),
    categoryId = idOrNull("categoryId"),
    fromMonth = month("fromMonth"),
    amount = intOrNull("amount"),
)

internal fun Recurring.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("type", type.rawValue)
    put("amount", amount)
    put("categoryId", categoryId?.toString())
    put("walletId", walletId.toString())
    put("toWalletId", toWalletId?.toString())
    put("memo", memo)
    put("frequency", frequency.rawValue)
    put("month", month)
    put("day", day)
    put("holidayShift", holidayShift.rawValue)
    put("closingDay", closingDay)
    put("fee", fee)
    put("finalAmount", finalAmount)
    put("billShift", billShift)
    put("startDate", startDate.toString())
    put("endDate", endDate?.toString())
    put("remindDaysBefore", remindDaysBefore)
    put("generatedUntil", generatedUntil?.toString())
    put("sortOrder", sortOrder)
    put("archivedAt", archivedAt)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.recurring(): Recurring {
    val holidayShift = rawOrNull("holidayShift") { HolidayShift.of(it) }

    return Recurring(
        id = id("id"),
        type = raw("type") { Entry.Kind.of(it) },
        amount = int("amount"),
        categoryId = idOrNull("categoryId"),
        walletId = id("walletId"),
        toWalletId = idOrNull("toWalletId"),
        memo = stringOrNull("memo"),
        frequency = raw("frequency") { Recurring.Frequency.of(it) },
        month = intOrNull("month"),
        day = int("day"),
        holidayShift = holidayShift ?: HolidayShift.none,
        closingDay = intOrNull("closingDay"),
        fee = intOrNull("fee"),
        finalAmount = intOrNull("finalAmount"),
        billShift = Recurring.clampedBillShift(intOrNull("billShift") ?: 0),
        startDate = date("startDate"),
        endDate = dateOrNull("endDate"),
        remindDaysBefore = intOrNull("remindDaysBefore"),
        generatedUntil = dateOrNull("generatedUntil"),
        sortOrder = int("sortOrder"),
        archivedAt = instantOrNull("archivedAt"),
        createdAt = instant("createdAt"),
        updatedAt = instant("updatedAt"),
    )
}
