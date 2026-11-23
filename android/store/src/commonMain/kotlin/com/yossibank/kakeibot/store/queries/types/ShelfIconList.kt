package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.shared.Identifier

data class ShelfIconList(
    val shelfIcons: List<ShelfIcon>,
    val icons: Map<Identifier<Icon>, Icon>,
)
