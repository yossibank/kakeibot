package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.WalletDraft
import com.yossibank.kakeibot.store.records.protocols.IconBackedTable
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.WalletRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.wallet
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.methods.WalletWriteError
import com.yossibank.kakeibot.store.writes.methods.WalletWriteException
import com.yossibank.kakeibot.store.writes.methods.hasRecords
import com.yossibank.kakeibot.store.writes.methods.hasValuations

val WalletTable = IconBackedTable<Wallet, WalletDraft>(
    name = "wallet",
    notFoundError = { WalletWriteException(WalletWriteError.walletNotFound) },
    iconNotFoundError = { WalletWriteException(WalletWriteError.iconNotFound) },
    iconId = { it.iconId },
    find = { walletDao().find(it.databaseValue)?.decoded(WalletRecord::wallet) },
    insert = { walletDao().insert(it.record()) },
    update = { walletDao().update(it.record()) },
    maxSortOrder = { walletDao().maxSortOrder() },
    locked = { draft, existing ->
        draft.locked(
            by = existing,
            hasRecords = hasRecords(existing.id),
            hasValuations = hasValuations(existing.id),
        )
    },
    archived = { wallet, archivedAt, at -> wallet.copy(archivedAt = archivedAt, updatedAt = at) },
    hideGuard = { isHidden ->
        if (isHidden && walletDao().countUnarchived() <= 1) {
            throw WalletWriteException(WalletWriteError.lastShownWallet)
        }
    },
)
