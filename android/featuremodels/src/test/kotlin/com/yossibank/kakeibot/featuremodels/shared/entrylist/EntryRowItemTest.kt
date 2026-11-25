package com.yossibank.kakeibot.featuremodels.shared.entrylist

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.support.ModelTestDatabase
import com.yossibank.kakeibot.store.queries.types.EntryList
import org.junit.Test
import kotlin.test.assertEquals

class EntryRowItemTest {
    private val now = ModelTestDatabase.now

    private val card = Wallet(
        name = "カード",
        kind = Wallet.Kind.card,
        iconId = Identifier(),
        initialBalance = 0,
        sortOrder = 0,
        createdAt = now,
        updatedAt = now,
    )

    private val bill = Recurring(
        type = Entry.Kind.transfer,
        amount = 0,
        categoryId = null,
        walletId = Identifier(),
        toWalletId = card.id,
        frequency = Recurring.Frequency.monthly,
        day = 27,
        holidayShift = HolidayShift.next,
        closingDay = 31,
        startDate = date("2026-01-01"),
        createdAt = now,
        updatedAt = now,
    )

    @Test
    fun showsBillDateOfMovedUsage() {
        val item = EntryRowItem.of(
            entry = entry(billMonth = "2027-02"),
            list = list(bill),
        )

        assertEquals("カード（3/1払い）", item.detail)
    }

    @Test
    fun keepsMonthWhenBillIsUnknown() {
        val item = EntryRowItem.of(
            entry = entry(billMonth = "2030-02"),
            list = list(bill),
        )

        assertEquals("カード（2月払い）", item.detail)
    }

    @Test
    fun skipsHiddenBillOfSameCard() {
        val hidden = bill.copy(
            id = Identifier(),
            day = 20,
            archivedAt = now,
        )

        val item = EntryRowItem.of(
            entry = entry(billMonth = "2027-02"),
            list = list(hidden, bill),
        )

        assertEquals("カード（3/1払い）", item.detail)
    }

    @Test
    fun keepsMonthWhenTwoBillsFit() {
        val other = bill.copy(
            id = Identifier(),
            day = 20,
        )

        val item = EntryRowItem.of(
            entry = entry(billMonth = "2027-02"),
            list = list(other, bill),
        )

        assertEquals("カード（2月払い）", item.detail)
    }

    private fun list(vararg bills: Recurring): EntryList = EntryList(
        days = emptyList(),
        categories = emptyMap(),
        tags = emptyMap(),
        wallets = mapOf(card.id to card),
        icons = emptyMap(),
        cardBills = bills.toList(),
    )

    private fun entry(billMonth: String): Entry = Entry(
        type = Entry.Kind.expense,
        amount = 500,
        date = date("2027-01-20"),
        categoryId = Identifier(),
        walletId = card.id,
        billMonth = checkNotNull(YearMonth.parse(billMonth)),
        createdAt = now,
        updatedAt = now,
    )

    private fun date(text: String): LocalDate = checkNotNull(LocalDate.parse(text))
}
