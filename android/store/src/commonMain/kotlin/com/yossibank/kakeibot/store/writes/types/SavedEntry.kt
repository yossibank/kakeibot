package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay

data class SavedEntry(
    val entry: Entry,
    val clearedNoSpendDays: List<NoSpendDay>,
)
