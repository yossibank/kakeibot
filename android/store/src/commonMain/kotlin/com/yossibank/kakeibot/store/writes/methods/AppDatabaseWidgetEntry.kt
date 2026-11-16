package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.queries.methods.fetchSetting
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryTagRecord
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecord
import com.yossibank.kakeibot.store.records.rows.entryTag
import com.yossibank.kakeibot.store.records.rows.entryTemplate
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.widgetEntry
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.WidgetRecord
import java.time.Instant

enum class WidgetEntryError {
    templateNotFound,
    amountMissing,
}

class WidgetEntryException(
    val error: WidgetEntryError,
) : Exception(error.name)

suspend fun AppDatabase.recordFromWidget(
    id: Identifier<EntryTemplate>,
    on: LocalDate,
    at: Instant,
): Entry = write {
    val template = templateDao().find(id.databaseValue)?.decoded(EntryTemplateRecord::entryTemplate)
        ?: throw WidgetEntryException(WidgetEntryError.templateNotFound)

    val draft = fetchEntryDraft(
        template = template,
        on = on,
    ) ?: throw WidgetEntryException(WidgetEntryError.amountMissing)

    val saved = saveEntryRecalculating(
        draft = draft,
        editing = null,
        at = at,
    )

    val record = WidgetRecord(
        entryId = saved.entry.id,
        clearedNoSpendDate = saved.clearedNoSpendDays.firstOrNull()?.date,
    )

    storeSetting(
        key = SettingKey.widgetEntry,
        to = record,
    )

    saved.entry
}

suspend fun AppDatabase.entryDraft(
    template: EntryTemplate,
    on: LocalDate,
): EntryDraft? = read {
    fetchEntryDraft(
        template = template,
        on = on,
    )
}

suspend fun AppDatabase.undoWidgetEntry(
    id: Identifier<Entry>,
    at: Instant = Instant.now(),
) {
    write {
        val entry = findEntry(id)

        entryDao().delete(id.databaseValue)

        if (entry != null) {
            recalculateCardBills(
                change = CardBillChange(before = listOf(entry)),
                at = at,
            )
        }

        val record = fetchSetting(SettingKey.widgetEntry)

        if (record == null || record.entryId != id) {
            return@write
        }

        val days = record.clearedNoSpendDate?.let { date ->
            listOf(
                NoSpendDay(
                    date = date,
                    createdAt = at,
                ),
            )
        } ?: emptyList()

        restoreNoSpendDays(days)

        storeSetting(
            key = SettingKey.widgetEntry,
            to = null,
        )
    }
}

internal suspend fun AppDatabase.fetchEntryDraft(
    template: EntryTemplate,
    on: LocalDate,
): EntryDraft? {
    val draft = template.entryDraft(on = on) ?: return null
    val tag = draft.tagId?.let { tagDao().find(it.databaseValue)?.decoded(EntryTagRecord::entryTag) }
    val tagId = if (tag?.archivedAt != null) null else draft.tagId

    val billMonth = billMonth(
        paidBy = template.walletId,
        type = template.type,
        on = on,
        shift = template.billShift,
    )

    return draft.copy(
        tagId = tagId,
        billMonth = billMonth,
    )
}
