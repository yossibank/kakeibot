package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.WalletDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.rows.AdjustmentRecord
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.EntryTagRecord
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecord
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.ValuationRecord
import com.yossibank.kakeibot.store.records.rows.WalletRecord
import com.yossibank.kakeibot.store.records.rows.adjustment
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.entryTag
import com.yossibank.kakeibot.store.records.rows.entryTemplate
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.rows.valuation
import com.yossibank.kakeibot.store.records.rows.wallet
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

enum class WalletWriteError {
    walletNotFound,
    iconNotFound,
    lastShownWallet,
    hasEntries,
}

class WalletWriteException(
    val error: WalletWriteError,
) : Exception(error.name)

suspend fun AppDatabase.saveWallet(
    draft: WalletDraft,
    editing: Identifier<Wallet>? = null,
    at: Instant,
): Wallet = write {
    if (editing != null) {
        updateWallet(
            id = editing,
            with = draft,
            at = at,
        )
    } else {
        insertWallet(
            draft = draft,
            at = at,
        )
    }
}

suspend fun AppDatabase.reorderWallets(
    ids: List<Identifier<Wallet>>,
    at: Instant,
) {
    write {
        reorder(
            table = "wallet",
            ids = ids.map { it.databaseValue },
            notFound = WalletWriteException(WalletWriteError.walletNotFound),
            now = at,
        )
    }
}

suspend fun AppDatabase.setWalletHidden(
    id: Identifier<Wallet>,
    isHidden: Boolean,
    at: Instant,
) {
    write {
        val wallet = findWallet(id) ?: throw WalletWriteException(WalletWriteError.walletNotFound)

        if (isHidden && walletDao().countUnarchived() <= 1) {
            throw WalletWriteException(WalletWriteError.lastShownWallet)
        }

        val updated = wallet.copy(
            archivedAt = if (isHidden) at else null,
            updatedAt = at,
        )

        walletDao().update(updated.record())
    }
}

suspend fun AppDatabase.deleteWallet(
    id: Identifier<Wallet>,
    at: Instant,
): Deletion = write {
    val wallet = findWallet(id) ?: throw WalletWriteException(WalletWriteError.walletNotFound)
    val key = id.databaseValue

    if (entryDao().countOfWallet(key) > 0) {
        throw WalletWriteException(WalletWriteError.hasEntries)
    }

    if (wallet.archivedAt == null && walletDao().countUnarchived() <= 1) {
        throw WalletWriteException(WalletWriteError.lastShownWallet)
    }

    val categories = categoryDao().ofWallet(key).map { it.decoded(EntryCategoryRecord::entryCategory) }
    val categoryIds = categories.map { it.id.databaseValue }
    val iconIds = categories.map { it.iconId.databaseValue } + wallet.iconId.databaseValue
    val icons = iconDao().withIds(iconIds).map { it.decoded(IconRecord::icon) }
    val tags = tagDao().ofCategories(categoryIds).map { it.decoded(EntryTagRecord::entryTag) }
    val recurrings = recurringDao().ofWallet(key).map { it.decoded(RecurringRecord::recurring) }
    val templates = templateDao().ofWallet(key).map { it.decoded(EntryTemplateRecord::entryTemplate) }
    val valuations = valuationDao().ofWallet(key).map { it.decoded(ValuationRecord::valuation) }
    val adjustments = adjustmentDao().ofWallet(key).map { it.decoded(AdjustmentRecord::adjustment) }

    val deletion = Deletion(
        icons = icons,
        wallets = listOf(wallet),
        categories = categories,
        tags = tags,
        recurrings = recurrings,
        templates = templates,
        valuations = valuations,
        adjustments = adjustments,
    )

    deleteRecurrings(
        recurrings = recurrings,
        at = at,
    )

    templateDao().deleteOfWallet(key)
    valuationDao().deleteOfWallet(key)
    adjustmentDao().deleteOfWallet(key)
    tagDao().deleteOfCategories(categoryIds)
    categoryDao().deleteOfWallet(key)
    walletDao().delete(key)
    iconDao().deleteIds(iconIds)

    deletion
}

private suspend fun AppDatabase.findWallet(id: Identifier<Wallet>): Wallet? =
    walletDao().find(id.databaseValue)?.decoded(WalletRecord::wallet)

private suspend fun AppDatabase.insertWallet(
    draft: WalletDraft,
    at: Instant,
): Wallet {
    val icon = draft.newIcon(at)
    val sortOrder = nextSortOrder(walletDao().maxSortOrder())

    val wallet = draft.newWallet(
        iconId = icon.id,
        sortOrder = sortOrder,
        at = at,
    )

    iconDao().insert(icon.record())
    walletDao().insert(wallet.record())

    return wallet
}

private suspend fun AppDatabase.updateWallet(
    id: Identifier<Wallet>,
    with: WalletDraft,
    at: Instant,
): Wallet {
    val existing = findWallet(id) ?: throw WalletWriteException(WalletWriteError.walletNotFound)

    val icon = iconDao().find(existing.iconId.databaseValue)?.decoded(IconRecord::icon)
        ?: throw WalletWriteException(WalletWriteError.iconNotFound)

    val locked = with.locked(
        by = existing,
        hasRecords = hasRecords(id),
        hasValuations = hasValuations(id),
    )

    val wallet = locked.applied(
        to = existing,
        at = at,
    )

    val updatedIcon = with.applied(
        to = icon,
        at = at,
    )

    iconDao().update(updatedIcon.record())
    walletDao().update(wallet.record())

    return wallet
}

private suspend fun AppDatabase.hasValuations(id: Identifier<Wallet>): Boolean =
    valuationDao().countOfWallet(id.databaseValue) > 0

private suspend fun AppDatabase.hasRecords(id: Identifier<Wallet>): Boolean {
    val key = id.databaseValue
    val hasEntries = entryDao().countOfWallet(key) > 0
    val hasRecurrings = recurringDao().countOfWallet(key) > 0
    val hasAdjustments = adjustmentDao().countOfWallet(key) > 0

    return hasEntries || hasRecurrings || hasAdjustments || hasValuations(id)
}
