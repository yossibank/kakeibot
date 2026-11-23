package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.store.records.protocols.SortableTable
import com.yossibank.kakeibot.store.writes.methods.RecurringWriteError
import com.yossibank.kakeibot.store.writes.methods.RecurringWriteException

object RecurringTable : SortableTable<Recurring> {
    override val name = "recurring"

    override fun notFound(): Throwable =
        RecurringWriteException(RecurringWriteError.recurringNotFound)
}
