package com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.review.ReviewKind

val ReviewKind.entryType: Entry.Kind?
    get() = when (this) {
        ReviewKind.expense -> Entry.Kind.expense
        ReviewKind.income -> Entry.Kind.income
        ReviewKind.balance -> null
    }
