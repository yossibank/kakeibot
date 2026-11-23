package com.yossibank.kakeibot.store.database

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.feeCategory
import com.yossibank.kakeibot.store.records.settingkeys.transferInCategory
import com.yossibank.kakeibot.store.records.settingkeys.transferOutCategory
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue
import java.time.Instant

internal suspend fun AppDatabase.feeCategoryId(at: Instant): Identifier<EntryCategory> = categoryId(
    key = SettingKey.feeCategory,
    seed = feeSeed,
    kind = EntryCategory.Kind.expense,
    now = at,
)

internal suspend fun AppDatabase.transferCategoryId(
    kind: EntryCategory.Kind,
    at: Instant,
): Identifier<EntryCategory> {
    val key = when (kind) {
        EntryCategory.Kind.expense -> SettingKey.transferOutCategory
        EntryCategory.Kind.income -> SettingKey.transferInCategory
    }

    return categoryId(
        key = key,
        seed = transferSeed,
        kind = kind,
        now = at,
    )
}

internal suspend fun AppDatabase.transferCategoryId(
    kind: EntryCategory.Kind,
    ofWallet: Identifier<Wallet>,
    at: Instant,
): Identifier<EntryCategory> {
    existingTransferCategoryId(
        kind = kind,
        ofWallet = ofWallet,
    )?.let { return it }

    val icon = insertIcon(
        seed = transferSeed,
        now = at,
    )

    val maxOrder = categoryDao().maxSortOrder(
        kind = kind.rawValue,
        walletId = ofWallet.databaseValue,
    )

    val category = EntryCategory(
        kind = kind,
        name = transferSeed.name,
        iconId = icon.id,
        sortOrder = nextSortOrder(maxOrder),
        walletId = ofWallet,
        createdAt = at,
        updatedAt = at,
    )

    categoryDao().insert(category.record())

    return category.id
}

internal suspend fun AppDatabase.existingTransferCategoryId(
    kind: EntryCategory.Kind,
    ofWallet: Identifier<Wallet>,
): Identifier<EntryCategory>? {
    val id = categoryDao().firstId(
        walletId = ofWallet.databaseValue,
        kind = kind.rawValue,
        name = transferSeed.name,
    )

    return id?.let { Identifier.fromDatabaseValue(it) }
}

private suspend fun AppDatabase.categoryId(
    key: SettingKey<Identifier<EntryCategory>?>,
    seed: Seed,
    kind: EntryCategory.Kind,
    now: Instant,
): Identifier<EntryCategory> {
    val stored = key.read(this)

    if (stored != null && categoryDao().exists(stored.databaseValue)) {
        return stored
    }

    val icon = insertIcon(
        seed = seed,
        now = now,
    )

    val maxOrder = categoryDao().maxSortOrder(kind.rawValue)

    val category = EntryCategory(
        kind = kind,
        name = seed.name,
        iconId = icon.id,
        sortOrder = nextSortOrder(maxOrder),
        createdAt = now,
        updatedAt = now,
    )

    categoryDao().insert(category.record())
    key.write(category.id, this)

    return category.id
}
