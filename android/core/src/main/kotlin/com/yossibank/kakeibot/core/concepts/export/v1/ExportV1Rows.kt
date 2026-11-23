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

internal fun ExportV1.App.row(): JsonObject = buildJsonObject {
    put("platform", platform.rawValue)
    put("version", version)
}

internal fun ExportV1.Tables.row(): JsonObject = buildJsonObject {
    put("icons", JsonArray(icons.map { it.row() }))
    put("shelfIcons", JsonArray(shelfIcons.map { it.row() }))
    put("wallets", JsonArray(wallets.map { it.row() }))
    put("valuations", JsonArray(valuations.map { it.row() }))
    put("adjustments", JsonArray(adjustments.map { it.row() }))
    put("categories", JsonArray(categories.map { it.row() }))
    put("tags", JsonArray(tags.map { it.row() }))
    put("entries", JsonArray(entries.map { it.row() }))
    put("entryItems", JsonArray(entryItems.map { it.row() }))
    put("itemNames", JsonArray(itemNames.map { it.row() }))
    put("templates", JsonArray(templates.map { it.row() }))
    put("budgets", JsonArray(budgets.map { it.row() }))
    put("recurrings", JsonArray(recurrings.map { it.row() }))
    put("rewardRules", JsonArray(rewardRules.map { it.row() }))
    put("rewardLogs", JsonArray(rewardLogs.map { it.row() }))
    put("rewardGoals", JsonArray(rewardGoals.map { it.row() }))
    put("calendarStamps", JsonArray(calendarStamps.map { it.row() }))
    put("noSpendDays", JsonArray(noSpendDays.map { it.row() }))
    put("themes", JsonArray(themes.map { it.row() }))
    put("settings", JsonArray(settings.map { it.row() }))
}

internal fun ExportRow.app(): ExportV1.App = ExportV1.App(
    platform = raw("platform") { ExportV1.Platform.of(it) },
    version = string("version"),
)

internal fun ExportRow.tables(): ExportV1.Tables = ExportV1.Tables(
    icons = rows("icons").map { it.icon() },
    shelfIcons = rowsOrEmpty("shelfIcons").map { it.shelfIcon() },
    wallets = rows("wallets").map { it.wallet() },
    valuations = rowsOrEmpty("valuations").map { it.valuation() },
    adjustments = rowsOrEmpty("adjustments").map { it.adjustment() },
    categories = rows("categories").map { it.category() },
    tags = rowsOrEmpty("tags").map { it.tag() },
    entries = rows("entries").map { it.entry() },
    entryItems = rowsOrEmpty("entryItems").map { it.entryItem() },
    itemNames = rowsOrEmpty("itemNames").map { it.itemName() },
    templates = rowsOrEmpty("templates").map { it.template() },
    budgets = rows("budgets").map { it.budget() },
    recurrings = rows("recurrings").map { it.recurring() },
    rewardRules = rows("rewardRules").map { it.rewardRule() },
    rewardLogs = rows("rewardLogs").map { it.rewardLog() },
    rewardGoals = rows("rewardGoals").map { it.rewardGoal() },
    calendarStamps = rows("calendarStamps").map { it.calendarStamp() },
    noSpendDays = rows("noSpendDays").map { it.noSpendDay() },
    themes = rows("themes").map { it.theme() },
    settings = rows("settings").mapNotNull { it.setting() },
)

internal fun JsonObjectBuilder.put(
    key: String,
    instant: Instant?,
) {
    put(key, instant?.let { InstantSerializer.format(it) })
}
