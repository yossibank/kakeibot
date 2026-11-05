package com.yossibank.kakeibot.core.concepts.entry

val Entry.Kind.title: String
    get() = when (this) {
        Entry.Kind.expense -> "支出"
        Entry.Kind.income -> "収入"
        Entry.Kind.transfer -> "振替"
    }
