package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier
import kotlinx.serialization.Serializable
import java.time.Instant

data class Wallet(
    val id: Identifier<Wallet> = Identifier(),
    val name: String,
    val kind: Kind,
    val iconId: Identifier<Icon>,
    val initialBalance: Int,
    val loanAmount: Int? = null,
    val sortOrder: Int,
    val archivedAt: Instant? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    @Serializable
    enum class Kind(
        val rawValue: String,
    ) {
        cash("cash"),
        bank("bank"),
        card("card"),
        emoney("emoney"),
        point("point"),
        other("other"),
        investment("investment"),
        loan("loan"),
        ;

        enum class Role {
            onHand,
            card,
            investment,
            loan,
        }

        companion object {
            fun of(rawValue: String): Kind? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }

    companion object
}
