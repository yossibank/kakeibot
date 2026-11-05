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

private fun JsonObjectBuilder.put(
    key: String,
    instant: Instant?,
) {
    put(key, instant?.let { InstantSerializer.format(it) })
}

private fun Icon.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("emoji", emoji)
    put("text", text)
    put("glyph", glyph?.rawValue)
    put("color", color)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.icon(): Icon = Icon(
    id = id("id"),
    emoji = stringOrNull("emoji"),
    text = stringOrNull("text"),
    glyph = rawOrNull("glyph") { Icon.Glyph.known(it) },
    color = string("color"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun ShelfIcon.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("iconId", iconId.toString())
    put("sortOrder", sortOrder)
    put("archivedAt", archivedAt)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.shelfIcon(): ShelfIcon = ShelfIcon(
    id = id("id"),
    iconId = id("iconId"),
    sortOrder = int("sortOrder"),
    archivedAt = instantOrNull("archivedAt"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun Wallet.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("name", name)
    put("kind", kind.rawValue)
    put("iconId", iconId.toString())
    put("initialBalance", initialBalance)
    put("loanAmount", loanAmount)
    put("sortOrder", sortOrder)
    put("archivedAt", archivedAt)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.wallet(): Wallet = Wallet(
    id = id("id"),
    name = string("name"),
    kind = raw("kind") { Wallet.Kind.of(it) },
    iconId = id("iconId"),
    initialBalance = int("initialBalance"),
    loanAmount = intOrNull("loanAmount"),
    sortOrder = int("sortOrder"),
    archivedAt = instantOrNull("archivedAt"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun Valuation.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("walletId", walletId.toString())
    put("date", date.toString())
    put("amount", amount)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.valuation(): Valuation = Valuation(
    id = id("id"),
    walletId = id("walletId"),
    date = date("date"),
    amount = int("amount"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun EntryCategory.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("kind", kind.rawValue)
    put("name", name)
    put("iconId", iconId.toString())
    put("sortOrder", sortOrder)
    put("archivedAt", archivedAt)
    put("walletId", walletId?.toString())
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.category(): EntryCategory = EntryCategory(
    id = id("id"),
    kind = raw("kind") { EntryCategory.Kind.of(it) },
    name = string("name"),
    iconId = id("iconId"),
    sortOrder = int("sortOrder"),
    archivedAt = instantOrNull("archivedAt"),
    walletId = idOrNull("walletId"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun EntryTag.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("categoryId", categoryId.toString())
    put("name", name)
    put("sortOrder", sortOrder)
    put("archivedAt", archivedAt)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.tag(): EntryTag = EntryTag(
    id = id("id"),
    categoryId = id("categoryId"),
    name = string("name"),
    sortOrder = int("sortOrder"),
    archivedAt = instantOrNull("archivedAt"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun Entry.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("type", type.rawValue)
    put("amount", amount)
    put("date", date.toString())
    put("categoryId", categoryId?.toString())
    put("tagId", tagId?.toString())
    put("templateId", templateId?.toString())
    put("walletId", walletId.toString())
    put("toWalletId", toWalletId?.toString())
    put("memo", memo)
    put("recurringId", recurringId?.toString())
    put("recurringDate", recurringDate?.toString())
    put("billMonth", billMonth?.toString())
    put("transferId", transferId?.toString())
    put("taxIncluded", taxIncluded)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.entry(): Entry = Entry(
    id = id("id"),
    type = raw("type") { Entry.Kind.of(it) },
    amount = int("amount"),
    date = date("date"),
    categoryId = idOrNull("categoryId"),
    tagId = idOrNull("tagId"),
    templateId = idOrNull("templateId"),
    walletId = id("walletId"),
    toWalletId = idOrNull("toWalletId"),
    memo = stringOrNull("memo"),
    recurringId = idOrNull("recurringId"),
    recurringDate = dateOrNull("recurringDate"),
    billMonth = monthOrNull("billMonth"),
    transferId = idOrNull("transferId"),
    taxIncluded = booleanOrNull("taxIncluded") ?: false,
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun EntryItem.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("entryId", entryId.toString())
    put("name", name)
    put("quantity", quantity)
    put("amount", amount)
    put("taxRate", taxRate?.rawValue)
    put("sortOrder", sortOrder)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.entryItem(): EntryItem = EntryItem(
    id = id("id"),
    entryId = id("entryId"),
    name = string("name"),
    quantity = int("quantity"),
    amount = int("amount"),
    taxRate = intOrNull("taxRate")?.let { taxRate(it) },
    sortOrder = int("sortOrder"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun taxRate(rawValue: Int): AmountCalculator.TaxRate =
    AmountCalculator.TaxRate.of(rawValue) ?: throw SerializationException("Invalid tax rate: $rawValue")

private fun ItemName.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("store", store)
    put("raw", raw)
    put("name", name)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.itemName(): ItemName = ItemName(
    id = id("id"),
    store = string("store"),
    raw = string("raw"),
    name = string("name"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun EntryTemplate.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("name", name)
    put("type", type.rawValue)
    put("amount", amount)
    put("categoryId", categoryId.toString())
    put("tagId", tagId?.toString())
    put("walletId", walletId.toString())
    put("memo", memo)
    put("billShift", billShift)
    put("sortOrder", sortOrder)
    put("archivedAt", archivedAt)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.template(): EntryTemplate = EntryTemplate(
    id = id("id"),
    name = string("name"),
    type = raw("type") { Entry.Kind.of(it) },
    amount = intOrNull("amount"),
    categoryId = id("categoryId"),
    tagId = idOrNull("tagId"),
    walletId = id("walletId"),
    memo = stringOrNull("memo"),
    billShift = Recurring.clampedBillShift(intOrNull("billShift") ?: 0),
    sortOrder = int("sortOrder"),
    archivedAt = instantOrNull("archivedAt"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun Budget.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("categoryId", categoryId?.toString())
    put("fromMonth", fromMonth.toString())
    put("amount", amount)
}

private fun ExportRow.budget(): Budget = Budget(
    id = id("id"),
    categoryId = idOrNull("categoryId"),
    fromMonth = month("fromMonth"),
    amount = intOrNull("amount"),
)

private fun Recurring.row(): JsonObject = buildJsonObject {
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

private fun ExportRow.recurring(): Recurring {
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

private fun RewardRule.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("name", name)
    put("amount", amount)
    put("iconId", iconId.toString())
    put("isActive", isActive)
    put("sortOrder", sortOrder)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.rewardRule(): RewardRule = RewardRule(
    id = id("id"),
    name = string("name"),
    amount = int("amount"),
    iconId = id("iconId"),
    isActive = boolean("isActive"),
    sortOrder = int("sortOrder"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun RewardLog.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("ruleId", ruleId.toString())
    put("date", date.toString())
    put("amount", amount)
    put("createdAt", createdAt)
}

private fun ExportRow.rewardLog(): RewardLog = RewardLog(
    id = id("id"),
    ruleId = id("ruleId"),
    date = date("date"),
    amount = int("amount"),
    createdAt = instant("createdAt"),
)

private fun RewardGoal.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("name", name)
    put("targetAmount", targetAmount)
    put("purchasedAt", purchasedAt)
    put("entryId", entryId?.toString())
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

private fun ExportRow.rewardGoal(): RewardGoal = RewardGoal(
    id = id("id"),
    name = string("name"),
    targetAmount = int("targetAmount"),
    purchasedAt = instantOrNull("purchasedAt"),
    entryId = idOrNull("entryId"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

private fun CalendarStamp.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("date", date.toString())
    put("iconId", iconId.toString())
    put("createdAt", createdAt)
}

private fun ExportRow.calendarStamp(): CalendarStamp = CalendarStamp(
    id = id("id"),
    date = date("date"),
    iconId = id("iconId"),
    createdAt = instant("createdAt"),
)

private fun NoSpendDay.row(): JsonObject = buildJsonObject {
    put("date", date.toString())
    put("createdAt", createdAt)
}

private fun ExportRow.noSpendDay(): NoSpendDay = NoSpendDay(
    date = date("date"),
    createdAt = instant("createdAt"),
)

private fun Theme.row(): JsonObject = buildJsonObject {
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

private fun ExportRow.theme(): Theme = Theme(
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

private fun Setting.row(): JsonObject = buildJsonObject {
    put("key", key.rawValue)
    put("value", value)
}

private fun ExportRow.setting(): Setting? {
    val key = string("key")
    val value = string("value")

    return Setting.Key.of(key)?.let {
        Setting(
            key = it,
            value = value,
        )
    }
}
