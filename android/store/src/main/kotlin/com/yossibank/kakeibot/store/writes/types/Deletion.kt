package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.theme.Theme
import com.yossibank.kakeibot.core.concepts.theme.ThemeChoice
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import java.util.UUID

data class Deletion(
    val id: UUID = UUID.randomUUID(),
    internal val icons: List<Icon> = emptyList(),
    internal val wallets: List<Wallet> = emptyList(),
    internal val categories: List<EntryCategory> = emptyList(),
    internal val tags: List<EntryTag> = emptyList(),
    internal val recurrings: List<Recurring> = emptyList(),
    internal val templates: List<EntryTemplate> = emptyList(),
    internal val budgets: List<Budget> = emptyList(),
    internal val valuations: List<Valuation> = emptyList(),
    internal val adjustments: List<Adjustment> = emptyList(),
    internal val shelfIcons: List<ShelfIcon> = emptyList(),
    internal val rewardRules: List<RewardRule> = emptyList(),
    internal val rewardLogs: List<RewardLog> = emptyList(),
    internal val themes: List<Theme> = emptyList(),
    internal val entries: List<Entry> = emptyList(),
    internal val themeChoice: ThemeChoice? = null,
) {
    companion object {
        fun merging(deletions: List<Deletion>): Deletion = Deletion(
            icons = deletions.flatMap { it.icons },
            wallets = deletions.flatMap { it.wallets },
            categories = deletions.flatMap { it.categories },
            tags = deletions.flatMap { it.tags },
            recurrings = deletions.flatMap { it.recurrings },
            templates = deletions.flatMap { it.templates },
            budgets = deletions.flatMap { it.budgets },
            valuations = deletions.flatMap { it.valuations },
            adjustments = deletions.flatMap { it.adjustments },
            shelfIcons = deletions.flatMap { it.shelfIcons },
            rewardRules = deletions.flatMap { it.rewardRules },
            rewardLogs = deletions.flatMap { it.rewardLogs },
            themes = deletions.flatMap { it.themes },
            entries = deletions.flatMap { it.entries },
            themeChoice = deletions.firstNotNullOfOrNull { it.themeChoice },
        )
    }
}
