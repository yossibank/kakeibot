package com.yossibank.kakeibot.core.concepts.category

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import kotlinx.serialization.Serializable
import java.time.Instant

data class EntryCategory(
    val id: Identifier<EntryCategory> = Identifier(),
    val kind: Kind,
    val name: String,
    val iconId: Identifier<Icon>,
    val sortOrder: Int,
    val archivedAt: Instant? = null,
    val walletId: Identifier<Wallet>? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    @Serializable
    enum class Kind(
        val rawValue: String,
    ) {
        expense("expense"),
        income("income"),
        ;

        companion object {
            fun of(rawValue: String): Kind? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }
}
