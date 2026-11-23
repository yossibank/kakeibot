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

internal fun EntryCategory.row(): JsonObject = buildJsonObject {
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

internal fun ExportRow.category(): EntryCategory = EntryCategory(
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

internal fun EntryTag.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("categoryId", categoryId.toString())
    put("name", name)
    put("sortOrder", sortOrder)
    put("archivedAt", archivedAt)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.tag(): EntryTag = EntryTag(
    id = id("id"),
    categoryId = id("categoryId"),
    name = string("name"),
    sortOrder = int("sortOrder"),
    archivedAt = instantOrNull("archivedAt"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

internal fun Entry.row(): JsonObject = buildJsonObject {
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

internal fun ExportRow.entry(): Entry = Entry(
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

internal fun EntryItem.row(): JsonObject = buildJsonObject {
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

internal fun ExportRow.entryItem(): EntryItem = EntryItem(
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

internal fun taxRate(rawValue: Int): AmountCalculator.TaxRate =
    AmountCalculator.TaxRate.of(rawValue)
        ?: throw SerializationException("Invalid tax rate: $rawValue")

internal fun ItemName.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("store", store)
    put("raw", raw)
    put("name", name)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.itemName(): ItemName = ItemName(
    id = id("id"),
    store = string("store"),
    raw = string("raw"),
    name = string("name"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

internal fun EntryTemplate.row(): JsonObject = buildJsonObject {
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

internal fun ExportRow.template(): EntryTemplate = EntryTemplate(
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
