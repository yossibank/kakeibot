package com.yossibank.kakeibot.store.records.values

import com.yossibank.kakeibot.core.concepts.date.LocalDate

val LocalDate.databaseValue: String
    get() = toString()

fun LocalDate.Companion.fromDatabaseValue(value: String): LocalDate? = parse(value)
