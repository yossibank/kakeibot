package com.yossibank.kakeibot.core.concepts.icon

import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class ShelfIcon(
    val id: Identifier<ShelfIcon> = Identifier(),
    val iconId: Identifier<Icon>,
    val sortOrder: Int,
    val archivedAt: Instant? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
)
