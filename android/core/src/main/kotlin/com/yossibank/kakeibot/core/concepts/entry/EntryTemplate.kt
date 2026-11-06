package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class EntryTemplate(
    val id: Identifier<EntryTemplate> = Identifier(),
    val name: String,
    val type: Entry.Kind,
    val amount: Int?,
    val categoryId: Identifier<EntryCategory>,
    val tagId: Identifier<EntryTag>? = null,
    val walletId: Identifier<Wallet>,
    val memo: String? = null,
    val billShift: Int = 0,
    val sortOrder: Int,
    val archivedAt: Instant? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    fun entryDraft(on: LocalDate): EntryDraft? {
        val amount = amount ?: return null

        return EntryDraft(
            type = type,
            amount = amount,
            date = on,
            categoryId = categoryId,
            tagId = tagId,
            templateId = id,
            walletId = walletId,
            memo = memo ?: "",
        )
    }
}
