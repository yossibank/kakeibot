package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.EntryItem

data class RemovedItem(
    val index: Int,
    val item: EntryItem.Draft,
)
