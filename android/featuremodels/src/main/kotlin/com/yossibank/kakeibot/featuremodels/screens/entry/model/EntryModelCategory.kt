package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.shared.Identifier

fun EntryModel.State.select(category: EntryCategory) {
    update { withCategory(category.id) }
    focus(EntryModel.Field.Amount)
}

fun EntryModel.State.toggleTag(id: Identifier<EntryTag>) {
    update { copy(tagId = if (tagId == id) null else id) }
}
