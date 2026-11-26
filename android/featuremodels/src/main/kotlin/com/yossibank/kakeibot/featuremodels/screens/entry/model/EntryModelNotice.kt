package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.shared.notice.EntryChange
import com.yossibank.kakeibot.store.writes.types.SavedEntry

internal fun EntryModel.Output.label(of: Entry): String = EntryChange.label(
    entry = of,
    category = { id -> allCategories.firstOrNull { it.id == id } },
    wallet = { id -> wallet(of = id) },
)

internal fun EntryModel.change(
    saved: SavedEntry,
    fee: Entry?,
): EntryChange {
    val original = input.original

    val kind = if (original == null) {
        EntryChange.Kind.Recorded
    } else {
        EntryChange.Kind.Edited(
            previous = original,
            previousFee = input.originalFee,
        )
    }

    return EntryChange(
        kind = kind,
        entry = saved.entry,
        label = output.label(of = saved.entry),
        fee = fee,
        clearedNoSpendDays = saved.clearedNoSpendDays,
    )
}
