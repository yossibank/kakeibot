package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.theme.ThemeChoice
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.queries.types.SetupProgress
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.WalletRecord
import com.yossibank.kakeibot.store.records.rows.wallet
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.reminderTime
import com.yossibank.kakeibot.store.records.settingkeys.theme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged

fun AppDatabase.setupProgressUpdates(): Flow<SetupProgress> = observation(
    "budget",
    "wallet",
    "valuation",
    "recurring",
    "setting",
) {
    fetchSetupProgress()
}.distinctUntilChanged()

internal suspend fun AppDatabase.fetchSetupProgress(): SetupProgress {
    val totals = fetchBudgets().filter { it.categoryId == null }
    val latestTotal = totals.maxByOrNull { it.fromMonth }
    val hasBudget = latestTotal?.amount != null

    val wallets = walletDao()
        .all()
        .map { it.decoded(WalletRecord::wallet) }
        .filter { it.archivedAt == null }

    val hasBalance = wallets.any { it.initialBalance != 0 }
    val hasValuation = valuationDao().count() > 0
    val hasRecurring = fetchRecurrings().isNotEmpty()
    val hasReminder = fetchSetting(SettingKey.reminderTime) != null
    val hasTheme = fetchSetting(SettingKey.theme) != ThemeChoice.System

    return SetupProgress(
        hasBudget = hasBudget,
        hasWalletBalance = hasBalance || hasValuation,
        hasRecurring = hasRecurring,
        hasReminder = hasReminder,
        hasTheme = hasTheme,
    )
}
