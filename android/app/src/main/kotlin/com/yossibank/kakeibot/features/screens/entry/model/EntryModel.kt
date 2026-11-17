package com.yossibank.kakeibot.features.screens.entry.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.date.shortName
import com.yossibank.kakeibot.designsystem.components.input.symbol
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entry
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.WriteError
import com.yossibank.kakeibot.store.writes.methods.WriteException
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import kotlinx.coroutines.CancellationException
import java.time.Instant

class EntryModel(
    private val database: AppDatabase,
    val today: LocalDate,
    private val editing: Identifier<Entry>? = null,
) {
    enum class Field {
        Category,
        Wallet,
        ToWallet,
        Date,
        Amount,
    }

    var type: Entry.Kind by mutableStateOf(Entry.Kind.expense)
        private set

    var calculator: AmountCalculator by mutableStateOf(AmountCalculator())
        private set

    var date: LocalDate by mutableStateOf(today)
        private set

    var categoryId: Identifier<EntryCategory>? by mutableStateOf(null)
        private set

    var walletId: Identifier<Wallet>? by mutableStateOf(null)
        private set

    var toWalletId: Identifier<Wallet>? by mutableStateOf(null)
        private set

    var memo: String by mutableStateOf("")

    var field: Field by mutableStateOf(Field.Amount)
        private set

    var message: String? by mutableStateOf(null)
        private set

    var isSaving: Boolean by mutableStateOf(false)
        private set

    private var options: EntryOptions? by mutableStateOf(null)

    val isEditing: Boolean
        get() = editing != null

    val amount: Int
        get() = calculator.amount

    val categories: List<EntryCategory>
        get() = when (type) {
            Entry.Kind.expense -> options?.expenseCategories ?: emptyList()
            Entry.Kind.income -> options?.incomeCategories ?: emptyList()
            Entry.Kind.transfer -> emptyList()
        }

    val wallets: List<Wallet>
        get() = options?.wallets ?: emptyList()

    val category: EntryCategory?
        get() = categories.firstOrNull { it.id == categoryId }

    val wallet: Wallet?
        get() = wallets.firstOrNull { it.id == walletId }

    val toWallet: Wallet?
        get() = wallets.firstOrNull { it.id == toWalletId }

    val walletTitle: String
        get() = when (type) {
            Entry.Kind.expense -> "支払い元"
            Entry.Kind.income -> "入金先"
            Entry.Kind.transfer -> "振替元"
        }

    val dateText: String
        get() {
            val name = when (date.days(until = today)) {
                0 -> "今日"
                1 -> "昨日"
                else -> date.monthDayText
            }

            return "$name（${date.weekday.shortName}）"
        }

    val expressionText: String?
        get() {
            val note = calculator.taxNote

            if (note != null) {
                return "${AmountText.number(note.base)} の税込み ${note.rate.rawValue}%"
            }

            if (!calculator.hasOperation) {
                return null
            }

            return calculator.tokens.joinToString(" ") { token ->
                when (token) {
                    is AmountCalculator.Token.Number -> AmountText.number(token.number)
                    is AmountCalculator.Token.Operation -> token.operation.symbol
                }
            }
        }

    fun icon(of: Identifier<Icon>): Icon? = options?.icons?.get(of)

    suspend fun load() {
        try {
            database.insertDefaultsIfEmpty(at = Instant.now())

            val loaded = database.entryOptions()

            val entry = editing?.let { database.entry(it) }

            options = loaded

            if (entry != null) {
                type = entry.type
                calculator = AmountCalculator(amount = entry.amount)
                date = entry.date
                categoryId = entry.categoryId
                walletId = entry.walletId
                toWalletId = entry.toWalletId
                memo = entry.memo ?: ""
            } else {
                categoryId = categories.firstOrNull()?.id
                walletId = loaded.wallets.firstOrNull()?.id
            }
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "読み込めませんでした"
        }
    }

    fun focus(field: Field) {
        this.field = field
    }

    fun select(type: Entry.Kind) {
        if (this.type == type) {
            return
        }

        this.type = type

        categoryId = categories.firstOrNull()?.id
        toWalletId = if (type == Entry.Kind.transfer) {
            toWalletId ?: wallets.firstOrNull { it.id != walletId }?.id
        } else {
            null
        }

        if (field == Field.Category || field == Field.ToWallet) {
            field = Field.Amount
        }

        message = null
    }

    fun select(category: EntryCategory) {
        categoryId = category.id
        field = Field.Amount
        message = null
    }

    fun select(wallet: Wallet) {
        walletId = wallet.id
        field = Field.Amount
    }

    fun selectDestination(wallet: Wallet) {
        toWalletId = wallet.id
        field = Field.Amount
        message = null
    }

    fun select(date: LocalDate) {
        this.date = date
        field = Field.Amount
    }

    fun press(key: AmountCalculator.Key) {
        calculator = calculator.press(key)
        message = null
    }

    suspend fun save(): Boolean {
        val walletId = walletId

        if (walletId == null || isSaving) {
            return false
        }

        val draft = EntryDraft(
            type = type,
            amount = amount,
            date = date,
            categoryId = categoryId,
            walletId = walletId,
            toWalletId = toWalletId,
            memo = memo,
        )

        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            message = message(of = problem)
            return false
        }

        isSaving = true

        try {
            database.saveEntry(
                draft = draft,
                editing = editing,
                at = Instant.now(),
            )

            return true
        } catch (error: CancellationException) {
            throw error
        } catch (error: WriteException) {
            message = if (error.error == WriteError.entryNotFound) {
                "記録が見つかりませんでした"
            } else {
                "保存できませんでした"
            }

            return false
        } catch (_: Exception) {
            message = "保存できませんでした"
            return false
        } finally {
            isSaving = false
        }
    }

    suspend fun delete(): Boolean {
        val editing = editing

        if (editing == null || isSaving) {
            return false
        }

        isSaving = true

        try {
            database.deleteEntry(id = editing)

            return true
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "削除できませんでした"
            return false
        } finally {
            isSaving = false
        }
    }

    fun startNext() {
        calculator = AmountCalculator()
        memo = ""
        field = Field.Amount
        message = null
    }

    private fun message(of: EntryDraft.Problem): String = when (of) {
        EntryDraft.Problem.amountNotPositive -> "金額を入れてください"
        EntryDraft.Problem.missingCategory -> "カテゴリを選んでください"
        EntryDraft.Problem.missingDestination -> "振替先を選んでください"
        EntryDraft.Problem.sameWallet -> "振替元と振替先を別にしてください"
        else -> "保存できませんでした"
    }
}
