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
}
