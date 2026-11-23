package com.yossibank.kakeibot.features.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

data class RecurringEditForm(
    val type: Entry.Kind,
    val month: Int,
    val day: Int,
    val startDate: LocalDate,
    val categoryId: Identifier<EntryCategory>? = null,
    val walletId: Identifier<Wallet>? = null,
    val toWalletId: Identifier<Wallet>? = null,
    val memo: String = "",
    val frequency: Recurring.Frequency = Recurring.Frequency.monthly,
    val holidayShift: HolidayShift = HolidayShift.none,
    val closingDay: Int? = null,
    val endDate: LocalDate? = null,
    val remindDaysBefore: Int? = null,
    val billShift: Int = 0,
) {
    fun withWallet(id: Identifier<Wallet>?): RecurringEditForm {
        if (id == walletId) {
            return this
        }

        return copy(
            walletId = id,
            billShift = 0,
        )
    }

    companion object {
        fun starting(
            today: LocalDate,
            type: Entry.Kind,
        ): RecurringEditForm = RecurringEditForm(
            type = type,
            month = today.month,
            day = today.day,
            startDate = today,
        )

        fun of(draft: RecurringDraft): RecurringEditForm = RecurringEditForm(
            type = draft.type,
            month = draft.month,
            day = draft.day,
            startDate = draft.startDate,
            categoryId = draft.categoryId,
            walletId = draft.walletId,
            toWalletId = draft.toWalletId,
            memo = draft.memo,
            frequency = draft.frequency,
            holidayShift = draft.holidayShift,
            closingDay = draft.closingDay,
            endDate = draft.endDate,
            remindDaysBefore = draft.remindDaysBefore,
            billShift = draft.billShift,
        )
    }
}
