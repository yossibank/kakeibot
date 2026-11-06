package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.AdjustmentRecord
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.EntryItemRecord
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.EntryTagRecord
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.ValuationRecord
import com.yossibank.kakeibot.store.records.rows.WalletRecord
import com.yossibank.kakeibot.store.records.rows.adjustment
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.entryItem
import com.yossibank.kakeibot.store.records.rows.entryTag
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.rows.valuation
import com.yossibank.kakeibot.store.records.rows.wallet
import com.yossibank.kakeibot.store.records.values.databaseValue
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first

fun AppDatabase.entryListUpdates(): Flow<EntryList> = observation(*entryListTables) {
    fetchEntryList()
}.distinctUntilChanged()

suspend fun AppDatabase.entryList(): EntryList = read {
    fetchEntryList()
}

suspend fun AppDatabase.latestEntryList(): EntryList = entryListUpdates().first()

suspend fun AppDatabase.entryOptions(): EntryOptions = read {
    fetchEntryOptions()
}

suspend fun AppDatabase.entry(id: Identifier<Entry>): Entry? = read {
    entryDao().find(id.databaseValue)?.decoded(EntryRecord::entry)
}

suspend fun AppDatabase.recentMemos(limit: Int): List<String> = read {
    entryDao().recentMemos(limit)
}

internal suspend fun AppDatabase.fetchEntryList(includesItems: Boolean = true): EntryList = fetchEntryList(
    entries = entryDao().all().map { it.decoded(EntryRecord::entry) },
    includesItems = includesItems,
)

internal suspend fun AppDatabase.fetchEntryList(
    entries: List<Entry>,
    includesItems: Boolean = false,
): EntryList {
    val categories = categoryDao()
        .all()
        .map { it.decoded(EntryCategoryRecord::entryCategory) }
        .associateBy { it.id }

    val days = EntryDay.grouping(
        entries = entries,
        categories = categories,
    )

    val tags = tagDao()
        .all()
        .map { it.decoded(EntryTagRecord::entryTag) }
        .associateBy { it.id }

    val wallets = walletDao()
        .all()
        .map { it.decoded(WalletRecord::wallet) }
        .associateBy { it.id }

    val valuations = valuationDao()
        .all()
        .map { it.decoded(ValuationRecord::valuation) }

    val adjustments = adjustmentDao()
        .inDateOrder()
        .map { it.decoded(AdjustmentRecord::adjustment) }

    val items = if (includesItems) {
        val ids = entries.map { it.id }.toSet()

        entryItemDao()
            .inEntryOrder()
            .map { it.decoded(EntryItemRecord::entryItem) }
            .filter { it.entryId in ids }
            .groupBy { it.entryId }
    } else {
        emptyMap()
    }

    return EntryList(
        days = days,
        categories = categories,
        tags = tags,
        wallets = wallets,
        valuations = valuations,
        adjustments = adjustments,
        icons = fetchIcons(),
        cardBills = fetchCardBills(),
        items = items,
    )
}

internal suspend fun AppDatabase.fetchIcons(): Map<Identifier<Icon>, Icon> = iconDao()
    .all()
    .map { it.decoded(IconRecord::icon) }
    .associateBy { it.id }

internal suspend fun AppDatabase.fetchIcons(ids: List<Identifier<Icon>>): Map<Identifier<Icon>, Icon> {
    val keys = ids.map { it.databaseValue }.distinct()

    return iconDao()
        .withIds(keys)
        .map { it.decoded(IconRecord::icon) }
        .associateBy { it.id }
}

private val entryListTables = arrayOf(
    "entry",
    "category",
    "tag",
    "wallet",
    "valuation",
    "adjustment",
    "icon",
    "recurring",
    "entry_item",
)

private suspend fun AppDatabase.fetchEntryOptions(): EntryOptions {
    val categories = categoryDao()
        .unarchivedWithoutWallet()
        .map { it.decoded(EntryCategoryRecord::entryCategory) }

    val tags = tagDao()
        .withoutWalletInOrder()
        .map { it.decoded(EntryTagRecord::entryTag) }

    val sharedCategories = categoryDao()
        .unarchivedOfWallets()
        .map { it.decoded(EntryCategoryRecord::entryCategory) }

    val sharedTags = tagDao()
        .ofWalletsInOrder()
        .map { it.decoded(EntryTagRecord::entryTag) }

    val wallets = walletDao()
        .unarchivedInOrder()
        .map { it.decoded(WalletRecord::wallet) }

    return EntryOptions(
        expenseCategories = categories.filter { it.kind == EntryCategory.Kind.expense },
        incomeCategories = categories.filter { it.kind == EntryCategory.Kind.income },
        tags = tags,
        wallets = wallets,
        icons = fetchIcons(),
        sharedCategories = sharedCategories,
        sharedTags = sharedTags,
    )
}

private suspend fun AppDatabase.fetchCardBills(): List<Recurring> = recurringDao()
    .cardBills()
    .map { it.decoded(RecurringRecord::recurring).copy(generatedUntil = null) }
