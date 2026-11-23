package com.yossibank.kakeibot.store.records.protocols

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.IconBackedDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import java.time.Instant

class IconBackedTable<Value : Any, Draft : IconBackedDraft<Value>>(
    override val name: String,
    private val notFoundError: () -> Throwable,
    private val iconNotFoundError: () -> Throwable,
    val iconId: (Value) -> Identifier<Icon>,
    val find: suspend AppDatabase.(Identifier<Value>) -> Value?,
    val insert: suspend AppDatabase.(Value) -> Unit,
    val update: suspend AppDatabase.(Value) -> Unit,
    val maxSortOrder: suspend AppDatabase.(Draft) -> Int?,
    val locked: suspend AppDatabase.(Draft, Value) -> Draft = { draft, _ -> draft },
    private val archived: (Value, Instant?, Instant) -> Value,
    private val hideGuard: suspend AppDatabase.(Boolean) -> Unit = {},
) : HidableTable<Value> {
    override fun notFound(): Throwable = notFoundError()

    fun iconNotFound(): Throwable = iconNotFoundError()

    override suspend fun hide(
        database: AppDatabase,
        id: Identifier<Value>,
        isHidden: Boolean,
        at: Instant,
    ) {
        val value = database.find(id) ?: throw notFound()

        database.hideGuard(isHidden)
        database.update(archived(value, if (isHidden) at else null, at))
    }
}
