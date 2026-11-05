package com.yossibank.kakeibot.core.concepts.receipt

import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class ItemName(
    val id: Identifier<ItemName> = Identifier(),
    val store: String,
    val raw: String,
    val name: String,
    val createdAt: Instant,
    val updatedAt: Instant,
)
