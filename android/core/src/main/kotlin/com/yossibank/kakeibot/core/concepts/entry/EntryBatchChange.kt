package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.shared.Identifier

sealed interface EntryBatchChange {
    data class Category(
        val id: Identifier<EntryCategory>,
    ) : EntryBatchChange

    data class Wallet(
        val id: Identifier<com.yossibank.kakeibot.core.concepts.wallet.Wallet>,
    ) : EntryBatchChange
}
