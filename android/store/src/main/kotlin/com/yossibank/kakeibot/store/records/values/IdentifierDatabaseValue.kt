package com.yossibank.kakeibot.store.records.values

import com.yossibank.kakeibot.core.shared.Identifier

val Identifier<*>.databaseValue: String
    get() = toString()

fun <Owner> Identifier.Companion.fromDatabaseValue(value: String): Identifier<Owner>? = parse(value)
