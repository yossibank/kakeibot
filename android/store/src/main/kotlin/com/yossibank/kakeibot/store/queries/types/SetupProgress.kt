package com.yossibank.kakeibot.store.queries.types

data class SetupProgress(
    val hasBudget: Boolean,
    val hasWalletBalance: Boolean,
    val hasRecurring: Boolean,
    val hasReminder: Boolean,
    val hasTheme: Boolean,
)
