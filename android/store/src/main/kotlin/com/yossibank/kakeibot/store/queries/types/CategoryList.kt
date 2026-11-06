package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier

data class CategoryList(
    val categories: List<EntryCategory>,
    val tags: List<EntryTag>,
    val icons: Map<Identifier<Icon>, Icon>,
)
