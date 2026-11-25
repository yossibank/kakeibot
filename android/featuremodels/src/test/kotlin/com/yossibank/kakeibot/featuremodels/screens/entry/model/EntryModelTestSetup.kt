package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.writes.methods.saveEntry

fun item(
    name: String,
    amount: Int,
    quantity: Int = 1,
    taxRate: AmountCalculator.TaxRate? = null,
) = EntryItem.Draft(
    name = name,
    quantity = quantity,
    amount = amount,
    taxRate = taxRate,
)

fun EntryModel.press(vararg digits: Int) {
    for (digit in digits) {
        state.press(AmountCalculator.Key.Digit(digit))
    }
}

suspend fun ModelTestSetup.saveTransfer(
    amount: Int,
    from: Identifier<Wallet>,
    to: Identifier<Wallet>,
    fee: Int = 0,
) {
    val count = database.entryList().entries.size

    val draft = EntryDraft(
        type = Entry.Kind.transfer,
        amount = amount,
        date = today,
        categoryId = null,
        walletId = from,
        toWalletId = to,
        fee = fee,
    )

    database.saveEntry(draft, at = now.plusSeconds(count.toLong()))
}

suspend fun ModelTestSetup.startSharing(walletId: Identifier<Wallet>): List<EntryCategory> {
    val options = options()

    return (options.expenseCategories + options.incomeCategories).map { own ->
        val shared = own.copy(
            id = Identifier(),
            walletId = walletId,
        )

        database.categoryDao().insert(shared.record())
        shared
    }
}

suspend fun ModelTestSetup.addSharedTag(
    category: EntryCategory,
    name: String,
): EntryTag {
    val tag = EntryTag(
        categoryId = category.id,
        name = name,
        sortOrder = 0,
        createdAt = now,
        updatedAt = now,
    )

    database.tagDao().insert(tag.record())
    return tag
}

suspend fun ModelTestSetup.loadedModel(editing: Identifier<Entry>? = null): EntryModel {
    val model = EntryModel(
        database = database,
        clock = ScreenClock.fixed(now),
        today = today,
        editing = editing,
    )

    model.load()
    return model
}

suspend fun ModelTestSetup.transferModel(): EntryModel {
    val model = loadedModel()
    model.select(type = Entry.Kind.transfer)
    return model
}
