package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import org.junit.Test
import kotlin.test.assertEquals

class EntryDeckTest {
    @Test
    fun pointsWalletsToTheTransferField() {
        val source = EntryModel.Field.Wallet
        val destination = EntryModel.Field.ToWallet

        assertEquals(EntryModel.Field.Wallet, source.field(of = Entry.Kind.expense))
        assertEquals(EntryModel.Field.Transfer, source.field(of = Entry.Kind.transfer))
        assertEquals(EntryModel.Field.Transfer, destination.field(of = Entry.Kind.transfer))
        assertEquals(EntryModel.Field.Fee, EntryModel.Field.Fee.field(of = Entry.Kind.transfer))
    }

    @Test
    fun ordersFieldsByTheirPlaces() {
        assertEquals(0, EntryModel.Field.Category.order(of = Entry.Kind.expense))
        assertEquals(1, EntryModel.Field.Wallet.order(of = Entry.Kind.expense))
        assertEquals(2, EntryModel.Field.Date.order(of = Entry.Kind.expense))
        assertEquals(3, EntryModel.Field.Amount.order(of = Entry.Kind.expense))
        assertEquals(0, EntryModel.Field.ToWallet.order(of = Entry.Kind.transfer))
        assertEquals(1, EntryModel.Field.Fee.order(of = Entry.Kind.transfer))
    }
}
