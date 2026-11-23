package com.yossibank.kakeibot.store.records.protocols

interface SortableTable<Value : Any> {
    val name: String

    fun notFound(): Throwable
}
