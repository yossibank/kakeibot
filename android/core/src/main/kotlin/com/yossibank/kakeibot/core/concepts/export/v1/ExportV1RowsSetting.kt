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

internal fun CalendarStamp.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("date", date.toString())
    put("iconId", iconId.toString())
    put("createdAt", createdAt)
}

internal fun ExportRow.calendarStamp(): CalendarStamp = CalendarStamp(
    id = id("id"),
    date = date("date"),
    iconId = id("iconId"),
    createdAt = instant("createdAt"),
)

internal fun NoSpendDay.row(): JsonObject = buildJsonObject {
    put("date", date.toString())
    put("createdAt", createdAt)
}

internal fun ExportRow.noSpendDay(): NoSpendDay = NoSpendDay(
    date = date("date"),
    createdAt = instant("createdAt"),
)

internal fun Theme.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("name", name)
    put("background", background)
    put("surface", surface)
    put("textPrimary", textPrimary)
    put("textSecondary", textSecondary)
    put("accent", accent)
    put("expense", expense)
    put("income", income)
    put("cornerRadius", cornerRadius)
    put("fontId", fontId)
    put("isBuiltin", isBuiltin)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.theme(): Theme = Theme(
    id = id("id"),
    name = string("name"),
    background = string("background"),
    surface = string("surface"),
    textPrimary = string("textPrimary"),
    textSecondary = string("textSecondary"),
    accent = string("accent"),
    expense = string("expense"),
    income = string("income"),
    cornerRadius = int("cornerRadius"),
    fontId = string("fontId"),
    isBuiltin = boolean("isBuiltin"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

internal fun Setting.row(): JsonObject = buildJsonObject {
    put("key", key.rawValue)
    put("value", value)
}

internal fun ExportRow.setting(): Setting? {
    val key = string("key")
    val value = string("value")

    return Setting.Key.of(key)?.let {
        Setting(
            key = it,
            value = value,
        )
    }
}
