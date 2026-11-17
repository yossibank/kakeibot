package com.yossibank.kakeibot.features.screens.settings.recurrings

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import kotlinx.coroutines.CancellationException
import java.time.Instant

class RecurringEditModel(
    private val database: AppDatabase,
    private val today: LocalDate,
    private val editing: Recurring?,
) {
    var type: Entry.Kind by mutableStateOf(editing?.type ?: Entry.Kind.expense)
        private set

    var calculator: AmountCalculator by mutableStateOf(
        AmountCalculator(
            amount =
                editing?.amount ?: 0,
        ),
    )
        private set

    var categoryId: Identifier<EntryCategory>? by mutableStateOf(editing?.categoryId)

    var walletId: Identifier<Wallet>? by mutableStateOf(editing?.walletId)

    var memo: String by mutableStateOf(editing?.memo ?: "")

    var frequency: Recurring.Frequency by mutableStateOf(
        editing?.frequency ?: Recurring.Frequency.monthly,
    )

    var month: Int by mutableStateOf(editing?.month ?: today.month)
        private set

    var day: Int by mutableStateOf(editing?.day ?: today.day)
        private set

    var message: String by mutableStateOf("")
        private set

    private var options: EntryOptions? by mutableStateOf(null)

    val isEditing: Boolean
        get() = editing != null

    val categories: List<EntryCategory>
        get() = when (type) {
            Entry.Kind.income -> options?.incomeCategories ?: emptyList()
            else -> options?.expenseCategories ?: emptyList()
        }

    val wallets: List<Wallet>
        get() = options?.wallets ?: emptyList()

    val scheduleText: String
        get() = Recurring.scheduleText(
            frequency = frequency,
            month = month,
            day = day,
        )

    fun icon(of: Identifier<Icon>): Icon? = options?.icons?.get(of)

    suspend fun load() {
        try {
            database.insertDefaultsIfEmpty(at = Instant.now())

            options = database.entryOptions()

            if (categoryId == null) {
                categoryId = categories.firstOrNull()?.id
            }

            if (walletId == null) {
                walletId = wallets.firstOrNull()?.id
            }
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "読み込めませんでした"
        }
    }

    fun select(type: Entry.Kind) {
        if (this.type == type) {
            return
        }

        this.type = type

        categoryId = categories.firstOrNull()?.id
    }

    fun press(key: AmountCalculator.Key) {
        calculator = calculator.press(key)
        message = ""
    }

    fun moveDay(by: Int) {
        day = (day + by - 1).mod(31) + 1
    }

    fun moveMonth(by: Int) {
        month = (month + by - 1).mod(12) + 1
    }

    suspend fun save(): Boolean {
        val draft = RecurringDraft(
            type = type,
            amount = calculator.amount,
            categoryId = categoryId,
            walletId = walletId,
            memo = memo,
            frequency = frequency,
            month = month,
            day = day,
            startDate = editing?.startDate ?: today,
        )

        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            message = when (problem) {
                RecurringDraft.Problem.amountNotPositive -> "金額を入れてください"
                RecurringDraft.Problem.missingCategory -> "カテゴリを選んでください"
                RecurringDraft.Problem.missingWallet -> "口座を選んでください"
                else -> "保存できませんでした"
            }

            return false
        }

        try {
            database.saveRecurring(
                draft = draft,
                editing = editing?.id,
                today = today,
                at = Instant.now(),
            )

            return true
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "保存できませんでした"
            return false
        }
    }

    suspend fun delete(): Boolean {
        val editing = editing ?: return false

        try {
            database.deleteRecurring(
                id = editing.id,
                at = Instant.now(),
            )

            return true
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "削除できませんでした"
            return false
        }
    }
}

fun Recurring.Companion.scheduleText(
    frequency: Recurring.Frequency,
    month: Int?,
    day: Int,
): String {
    val dayText = if (day == 31) "末日" else "$day 日"

    return when (frequency) {
        Recurring.Frequency.monthly -> "毎月 $dayText"
        Recurring.Frequency.yearly -> "毎年 ${month ?: 1} 月 $dayText"
    }
}
