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

internal fun Icon.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("emoji", emoji)
    put("text", text)
    put("glyph", glyph?.rawValue)
    put("color", color)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.icon(): Icon = Icon(
    id = id("id"),
    emoji = stringOrNull("emoji"),
    text = stringOrNull("text"),
    glyph = rawOrNull("glyph") { Icon.Glyph.known(it) },
    color = string("color"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

internal fun ShelfIcon.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("iconId", iconId.toString())
    put("sortOrder", sortOrder)
    put("archivedAt", archivedAt)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.shelfIcon(): ShelfIcon = ShelfIcon(
    id = id("id"),
    iconId = id("iconId"),
    sortOrder = int("sortOrder"),
    archivedAt = instantOrNull("archivedAt"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

internal fun Wallet.row(): JsonObject = buildJsonObject {
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

internal fun ExportRow.wallet(): Wallet = Wallet(
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

internal fun Valuation.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("walletId", walletId.toString())
    put("date", date.toString())
    put("amount", amount)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.valuation(): Valuation = Valuation(
    id = id("id"),
    walletId = id("walletId"),
    date = date("date"),
    amount = int("amount"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

internal fun Adjustment.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("walletId", walletId.toString())
    put("date", date.toString())
    put("amount", amount)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.adjustment(): Adjustment = Adjustment(
    id = id("id"),
    walletId = id("walletId"),
    date = date("date"),
    amount = long("amount"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)
