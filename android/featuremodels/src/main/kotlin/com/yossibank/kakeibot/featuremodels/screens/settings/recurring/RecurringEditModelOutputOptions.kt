package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.notification.NotificationAuthorization
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.recurring.billChoiceCount
import com.yossibank.kakeibot.core.concepts.recurring.billDates
import com.yossibank.kakeibot.core.concepts.recurring.cardBill
import com.yossibank.kakeibot.core.concepts.recurring.endDate
import com.yossibank.kakeibot.core.concepts.recurring.maxCount
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryText
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.latestEntryList
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

val RecurringEditModel.Output.walletTitle: String
    get() = EntryText.walletTitle(state.fields.form.type)

val RecurringEditModel.Output.billRecurring: Recurring?
    get() {
        if (state.fields.form.type == Entry.Kind.transfer) {
            return null
        }

        return input.cardBills.cardBill(paidBy = state.fields.form.walletId)
    }

val RecurringEditModel.Output.billDates: List<LocalDate>
    get() {
        val bill = billRecurring ?: return emptyList()
        val next = previewRow.next ?: return emptyList()

        return bill.billDates(
            used = next,
            count = Recurring.billChoiceCount,
        )
    }

val RecurringEditModel.Output.canUseClosingDay: Boolean
    get() = state.fields.form.type == Entry.Kind.transfer &&
        selectedDestination?.kind == Wallet.Kind.card

val RecurringEditModel.Output.isCardBill: Boolean
    get() = canUseClosingDay && state.fields.form.closingDay != null

val RecurringEditModel.Output.isLoanRepayment: Boolean
    get() = state.fields.form.type == Entry.Kind.transfer &&
        selectedDestination?.kind == Wallet.Kind.loan

val RecurringEditModel.Output.isNotificationDenied: Boolean
    get() {
        val isDenied = input.authorization == NotificationAuthorization.denied
        return state.fields.form.remindDaysBefore != null && isDenied
    }

val RecurringEditModel.Output.categories: List<EntryCategory>
    get() = when (state.fields.form.type) {
        Entry.Kind.expense -> input.options?.expenseCategories.orEmpty()
        Entry.Kind.income -> input.options?.incomeCategories.orEmpty()
        Entry.Kind.transfer -> emptyList()
    }

val RecurringEditModel.Output.wallets: List<Wallet>
    get() = input.options?.wallets.orEmpty()

val RecurringEditModel.Output.selectedCategory: EntryCategory?
    get() = categories.firstOrNull { it.id == state.fields.form.categoryId }

val RecurringEditModel.Output.selectedWallet: Wallet?
    get() = wallets.firstOrNull { it.id == state.fields.form.walletId }

val RecurringEditModel.Output.selectedDestination: Wallet?
    get() = wallets.firstOrNull { it.id == state.fields.form.toWalletId }

internal fun RecurringEditModel.Output.message(problem: RecurringDraft.Problem): String =
    when (problem) {
        RecurringDraft.Problem.amountNotPositive -> "金額を入れてください"
        RecurringDraft.Problem.missingCategory -> "カテゴリを選んでください"
        RecurringDraft.Problem.missingWallet -> "${walletTitle}を選んでください"
        RecurringDraft.Problem.missingDestination -> "${EntryText.destinationTitle}を選んでください"
        RecurringDraft.Problem.sameWallet -> "振替元と振替先を別にしてください"
        RecurringDraft.Problem.endBeforeStart -> "終わりを始まりより後にしてください"
        else -> ModelTask.saveFailed
    }
