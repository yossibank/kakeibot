package com.yossibank.kakeibot.store.records.values

import com.yossibank.kakeibot.core.concepts.date.YearMonth

val YearMonth.databaseValue: String
    get() = toString()

fun YearMonth.Companion.fromDatabaseValue(value: String): YearMonth? = parse(value)
