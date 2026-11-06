package com.yossibank.kakeibot.store.database

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.WalletRecord
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.wallet
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.feeCategory
import com.yossibank.kakeibot.store.records.settingkeys.transferInCategory
import com.yossibank.kakeibot.store.records.settingkeys.transferOutCategory
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue
import java.time.Instant

suspend fun AppDatabase.insertDefaultsIfEmpty(at: Instant) {
    write {
        if (walletDao().count() != 0 || categoryDao().countWithoutWallet() != 0) {
            return@write
        }

        insertDefaults(at)
    }
}

suspend fun AppDatabase.insertShelfIfEmpty(at: Instant) {
    write {
        if (shelfIconDao().count() != 0) {
            return@write
        }

        insertShelf(at)
    }
}

suspend fun AppDatabase.insertTemplatesIfEmpty(at: Instant) {
    write {
        if (templateDao().count() != 0) {
            return@write
        }

        insertTemplates(at)
    }
}

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

private data class Seed(
    val name: String,
    val glyph: Icon.Glyph,
    val color: String,
)

private val wallets = listOf(
    Seed(
        name = "財布",
        glyph = Icon.Glyph.cash,
        color = "#C9A465",
    ) to Wallet.Kind.cash,
    Seed(
        name = "銀行",
        glyph = Icon.Glyph.bank,
        color = "#4A6FA5",
    ) to Wallet.Kind.bank,
)

private val expenseCategories = listOf(
    Seed(
        name = "食費",
        glyph = Icon.Glyph.food,
        color = "#E07A5F",
    ),
    Seed(
        name = "日用品",
        glyph = Icon.Glyph.daily,
        color = "#81B29A",
    ),
    Seed(
        name = "交通",
        glyph = Icon.Glyph.transit,
        color = "#3D5A80",
    ),
    Seed(
        name = "交際",
        glyph = Icon.Glyph.social,
        color = "#F2CC8F",
    ),
    Seed(
        name = "趣味",
        glyph = Icon.Glyph.hobby,
        color = "#9C6ADE",
    ),
    Seed(
        name = "衣服",
        glyph = Icon.Glyph.clothes,
        color = "#5FA8D3",
    ),
    Seed(
        name = "美容",
        glyph = Icon.Glyph.beauty,
        color = "#E5989B",
    ),
    Seed(
        name = "医療",
        glyph = Icon.Glyph.medical,
        color = "#6CBF84",
    ),
    Seed(
        name = "住まい",
        glyph = Icon.Glyph.home,
        color = "#B08968",
    ),
    Seed(
        name = "通信",
        glyph = Icon.Glyph.phone,
        color = "#577590",
    ),
    Seed(
        name = "光熱費",
        glyph = Icon.Glyph.utility,
        color = "#F4A261",
    ),
    Seed(
        name = "その他",
        glyph = Icon.Glyph.other,
        color = "#8D99AE",
    ),
)

private val incomeCategories = listOf(
    Seed(
        name = "給料",
        glyph = Icon.Glyph.salary,
        color = "#2A9D8F",
    ),
    Seed(
        name = "臨時収入",
        glyph = Icon.Glyph.bonus,
        color = "#E9C46A",
    ),
    Seed(
        name = "その他",
        glyph = Icon.Glyph.other,
        color = "#8D99AE",
    ),
)

private val feeSeed = Seed("手数料", Icon.Glyph.coin, "#A68A64")

private val transferSeed = Seed("振替", Icon.Glyph.banknote, "#7A8B99")

private val templates = listOf(
    "コンビニ" to "食費",
    "ランチ" to "食費",
    "電車" to "交通",
    "日用品" to "日用品",
)

private val shelf = listOf(
    Icon.Glyph.star to "#C9A465",
    Icon.Glyph.party to "#E07A5F",
    Icon.Glyph.trophy to "#E9C46A",
    Icon.Glyph.cake to "#E5989B",
    Icon.Glyph.fitness to "#6CBF84",
    Icon.Glyph.travel to "#5FA8D3",
    Icon.Glyph.sun to "#F4A261",
    Icon.Glyph.moon to "#577590",
)

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

private suspend fun AppDatabase.insertDefaults(now: Instant) {
    for ((order, pair) in wallets.withIndex()) {
        val (seed, kind) = pair

        val icon = insertIcon(
            seed = seed,
            now = now,
        )

        val wallet = Wallet(
            name = seed.name,
            kind = kind,
            iconId = icon.id,
            initialBalance = 0,
            sortOrder = order,
            createdAt = now,
            updatedAt = now,
        )

        walletDao().insert(wallet.record())
    }

    insertCategories(
        seeds = expenseCategories,
        kind = EntryCategory.Kind.expense,
        now = now,
    )

    insertCategories(
        seeds = incomeCategories,
        kind = EntryCategory.Kind.income,
        now = now,
    )
}

private suspend fun AppDatabase.insertCategories(
    seeds: List<Seed>,
    kind: EntryCategory.Kind,
    now: Instant,
) {
    for ((order, seed) in seeds.withIndex()) {
        val icon = insertIcon(
            seed = seed,
            now = now,
        )

        val category = EntryCategory(
            kind = kind,
            name = seed.name,
            iconId = icon.id,
            sortOrder = order,
            createdAt = now,
            updatedAt = now,
        )

        categoryDao().insert(category.record())
    }
}

private suspend fun AppDatabase.insertTemplates(now: Instant) {
    val wallets = walletDao().all()
        .map { it.decoded(WalletRecord::wallet) }
        .filter { it.archivedAt == null }
        .sortedBy { it.sortOrder }

    val wallet = wallets.firstOrNull { it.kind == Wallet.Kind.cash } ?: wallets.firstOrNull() ?: return

    val categories = categoryDao().withoutWallet()
        .map { it.decoded(EntryCategoryRecord::entryCategory) }
        .filter { it.kind == EntryCategory.Kind.expense && it.archivedAt == null }

    val seeds = templates.mapNotNull { (name, categoryName) ->
        categories.firstOrNull { it.name == categoryName }?.let { name to it }
    }

    for ((order, pair) in seeds.withIndex()) {
        val (name, category) = pair

        val template = EntryTemplate(
            name = name,
            type = Entry.Kind.expense,
            amount = null,
            categoryId = category.id,
            walletId = wallet.id,
            sortOrder = order,
            createdAt = now,
            updatedAt = now,
        )

        templateDao().insert(template.record())
    }
}

private suspend fun AppDatabase.insertShelf(now: Instant) {
    for ((order, pair) in shelf.withIndex()) {
        val (glyph, color) = pair

        val icon = insertIcon(
            glyph = glyph,
            color = color,
            now = now,
        )

        val shelfIcon = ShelfIcon(
            iconId = icon.id,
            sortOrder = order,
            createdAt = now,
            updatedAt = now,
        )

        shelfIconDao().insert(shelfIcon.record())
    }
}

private suspend fun AppDatabase.insertIcon(
    seed: Seed,
    now: Instant,
): Icon = insertIcon(
    glyph = seed.glyph,
    color = seed.color,
    now = now,
)

private suspend fun AppDatabase.insertIcon(
    glyph: Icon.Glyph,
    color: String,
    now: Instant,
): Icon {
    val icon = Icon(
        emoji = null,
        text = null,
        glyph = glyph,
        color = color,
        createdAt = now,
        updatedAt = now,
    )

    iconDao().insert(icon.record())

    return icon
}
