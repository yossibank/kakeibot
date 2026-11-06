package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.amount

fun EntryList.title(of: Recurring): String? {
    val memo = of.memo?.takeIf { it.isNotEmpty() }
    val category = of.categoryId?.let { categories[it] }

    return memo ?: category?.name
}

fun EntryList.place(of: Recurring): String? {
    val wallet = wallets[of.walletId]

    if (of.type != Entry.Kind.transfer) {
        return wallet?.name
    }

    val destination = of.toWalletId?.let { wallets[it] }

    return listOfNotNull(
        wallet?.name,
        destination?.name,
    ).joinToString(" → ")
}

fun EntryList.amount(
    of: Recurring,
    on: LocalDate,
): Long {
    val entries = days.flatMap { it.entries }

    return of.amount(
        paidOn = on,
        entries = entries,
    )
}

fun EntryList.icon(of: Recurring): Icon? {
    val category = of.categoryId?.let { categories[it] }

    val iconId = if (of.type == Entry.Kind.transfer) {
        wallets[of.walletId]?.iconId
    } else {
        category?.iconId
    }

    return iconId?.let { icons[it] }
}
