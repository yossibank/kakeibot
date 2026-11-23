package com.yossibank.kakeibot.store.records.protocols

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue
import java.time.Instant

interface WalletDatedRecord {
    val id: String
    val walletId: String
    val date: String
    val createdAt: String
    val updatedAt: String
}

internal class WalletDatedFields<Owner>(
    val id: Identifier<Owner>,
    val walletId: Identifier<Wallet>,
    val date: LocalDate,
    val createdAt: Instant,
    val updatedAt: Instant,
)

internal class WalletDatedColumns(
    val id: String,
    val walletId: String,
    val date: String,
    val createdAt: String,
    val updatedAt: String,
)

internal fun <Owner> walletDatedColumns(
    id: Identifier<Owner>,
    walletId: Identifier<Wallet>,
    date: LocalDate,
    createdAt: Instant,
    updatedAt: Instant,
): WalletDatedColumns = WalletDatedColumns(
    id = id.databaseValue,
    walletId = walletId.databaseValue,
    date = date.databaseValue,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

internal fun <Owner> WalletDatedRecord.decodedFields(): WalletDatedFields<Owner>? {
    val id = Identifier.fromDatabaseValue<Owner>(id) ?: return null
    val walletId = Identifier.fromDatabaseValue<Wallet>(walletId) ?: return null
    val date = LocalDate.fromDatabaseValue(date) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return WalletDatedFields(
        id = id,
        walletId = walletId,
        date = date,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}
