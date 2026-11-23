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

internal fun RewardRule.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("name", name)
    put("amount", amount)
    put("iconId", iconId.toString())
    put("isActive", isActive)
    put("sortOrder", sortOrder)
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.rewardRule(): RewardRule = RewardRule(
    id = id("id"),
    name = string("name"),
    amount = int("amount"),
    iconId = id("iconId"),
    isActive = boolean("isActive"),
    sortOrder = int("sortOrder"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)

internal fun RewardLog.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("ruleId", ruleId.toString())
    put("date", date.toString())
    put("amount", amount)
    put("createdAt", createdAt)
}

internal fun ExportRow.rewardLog(): RewardLog = RewardLog(
    id = id("id"),
    ruleId = id("ruleId"),
    date = date("date"),
    amount = int("amount"),
    createdAt = instant("createdAt"),
)

internal fun RewardGoal.row(): JsonObject = buildJsonObject {
    put("id", id.toString())
    put("name", name)
    put("targetAmount", targetAmount)
    put("purchasedAt", purchasedAt)
    put("entryId", entryId?.toString())
    put("createdAt", createdAt)
    put("updatedAt", updatedAt)
}

internal fun ExportRow.rewardGoal(): RewardGoal = RewardGoal(
    id = id("id"),
    name = string("name"),
    targetAmount = int("targetAmount"),
    purchasedAt = instantOrNull("purchasedAt"),
    entryId = idOrNull("entryId"),
    createdAt = instant("createdAt"),
    updatedAt = instant("updatedAt"),
)
