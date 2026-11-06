package com.yossibank.kakeibot.core.concepts.category

import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class EntryTag(
    val id: Identifier<EntryTag> = Identifier(),
    val categoryId: Identifier<EntryCategory>,
    val name: String,
    val sortOrder: Int,
    val archivedAt: Instant? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
)
