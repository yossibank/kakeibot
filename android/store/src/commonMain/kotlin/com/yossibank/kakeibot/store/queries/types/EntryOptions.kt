package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

data class EntryOptions(
    val expenseCategories: List<EntryCategory>,
    val incomeCategories: List<EntryCategory>,
    val tags: List<EntryTag>,
    val wallets: List<Wallet>,
    val icons: Map<Identifier<Icon>, Icon>,
    val sharedCategories: List<EntryCategory> = emptyList(),
    val sharedTags: List<EntryTag> = emptyList(),
)
