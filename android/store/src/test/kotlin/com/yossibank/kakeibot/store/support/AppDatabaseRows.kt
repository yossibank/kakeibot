package com.yossibank.kakeibot.store.support

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.rows.BudgetRecord
import com.yossibank.kakeibot.store.records.rows.budget
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

suspend fun AppDatabase.insertEntry(
    type: Entry.Kind = Entry.Kind.expense,
    amount: Int,
    date: LocalDate,
    categoryId: Identifier<EntryCategory>?,
    walletId: Identifier<Wallet>,
    memo: String? = null,
    billMonth: YearMonth? = null,
    items: List<Pair<String, Int>> = emptyList(),
    at: Instant,
): Entry {
    val entry = Entry(
        type = type,
        amount = amount,
        date = date,
        categoryId = categoryId,
        walletId = walletId,
        memo = memo,
        billMonth = billMonth,
        createdAt = at,
        updatedAt = at,
    )

    write {
        entryDao().insert(entry.record())

        for ((order, item) in items.withIndex()) {
            val (name, price) = item

            val row = EntryItem(
                entryId = entry.id,
                name = name,
                amount = price,
                sortOrder = order,
                createdAt = at,
                updatedAt = at,
            )

            entryItemDao().insert(row.record())
        }
    }

    return entry
}

suspend fun AppDatabase.setBudget(
    amount: Int?,
    from: YearMonth,
    categoryId: Identifier<EntryCategory>? = null,
) {
    val existing = budgetDao()
        .all()
        .map { it.decoded(BudgetRecord::budget) }
        .firstOrNull { it.categoryId == categoryId && it.fromMonth == from }

    if (existing == null) {
        val budget = Budget(
            categoryId = categoryId,
            fromMonth = from,
            amount = amount,
        )

        budgetDao().insert(budget.record())
    } else {
        execute(
            "UPDATE budget SET amount = ? WHERE id = ?",
            amount,
            existing.id.databaseValue,
        )
    }
}

suspend fun <Value> AppDatabase.setSetting(
    key: SettingKey<Value>,
    value: Value,
) {
    write {
        key.write(value, this)
    }
}

suspend fun AppDatabase.markNoSpendDay(
    date: LocalDate,
    at: Instant,
) {
    val day = NoSpendDay(
        date = date,
        createdAt = at,
    )

    noSpendDayDao().insert(day.record())
}

suspend fun AppDatabase.insertRewardRule(
    name: String,
    amount: Int,
    glyph: Icon.Glyph,
    color: String,
    at: Instant,
): RewardRule = write {
    val icon = Icon(
        emoji = null,
        text = null,
        glyph = glyph,
        color = color,
        createdAt = at,
        updatedAt = at,
    )

    val maxOrder = rewardRuleDao().all().maxOfOrNull { it.sortOrder }

    val rule = RewardRule(
        name = name,
        amount = amount,
        iconId = icon.id,
        isActive = true,
        sortOrder = nextSortOrder(maxOrder),
        createdAt = at,
        updatedAt = at,
    )

    iconDao().insert(icon.record())
    rewardRuleDao().insert(rule.record())

    rule
}

suspend fun AppDatabase.insertRewardLog(
    rule: RewardRule,
    date: LocalDate,
    at: Instant,
) {
    val log = RewardLog(
        ruleId = rule.id,
        date = date,
        amount = rule.amount,
        createdAt = at,
    )

    rewardLogDao().insert(log.record())
}

suspend fun AppDatabase.hideRewardRule(
    id: Identifier<RewardRule>,
    at: Instant,
) {
    execute(
        "UPDATE reward_rule SET is_active = 0, updated_at = ? WHERE id = ?",
        at.storedValue,
        id.databaseValue,
    )
}
