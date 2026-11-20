package com.yossibank.kakeibot.features.screens.settings.templates

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.cardBill
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.saveTemplate
import kotlinx.coroutines.CancellationException
import java.time.Instant

class TemplateEditModel(
    private val database: AppDatabase,
    draft: EntryTemplateDraft,
) {
    var name: String by mutableStateOf(draft.name)

    var memo: String by mutableStateOf(draft.memo)

    val type: Entry.Kind = draft.type

    var calculator: AmountCalculator by mutableStateOf(AmountCalculator(amount = draft.amount ?: 0))
        private set

    var categoryId: Identifier<EntryCategory>? by mutableStateOf(draft.categoryId)
        private set

    var tagId: Identifier<EntryTag>? by mutableStateOf(draft.tagId)
        private set

    var walletId: Identifier<Wallet>? by mutableStateOf(draft.walletId)
        private set

    var billShift: Int by mutableStateOf(draft.billShift)

    var message: String by mutableStateOf("")
        private set

    var isSaving: Boolean by mutableStateOf(false)
        private set

    private var options: EntryOptions? by mutableStateOf(null)
    private var cardBills: List<Recurring> by mutableStateOf(emptyList())

    val billRecurring: Recurring?
        get() = cardBills.cardBill(paidBy = walletId)

    val category: EntryCategory?
        get() = categories.firstOrNull { it.id == categoryId }

    val wallet: Wallet?
        get() = wallets.firstOrNull { it.id == walletId }

    val tag: EntryTag?
        get() = tags.firstOrNull { it.id == tagId }

    val detail: String
        get() = listOfNotNull(category?.name, tag?.name, wallet?.name).joinToString("・")

    val amount: Int?
        get() = calculator.amount.takeIf { it > 0 }

    val walletTitle: String
        get() = if (type == Entry.Kind.income) "入金先" else "支払い元"

    val categories: List<EntryCategory>
        get() = when (type) {
            Entry.Kind.income -> options?.incomeCategories ?: emptyList()
            else -> options?.expenseCategories ?: emptyList()
        }

    val wallets: List<Wallet>
        get() = options?.wallets ?: emptyList()

    val tags: List<EntryTag>
        get() = (options?.tags ?: emptyList()).filter { tag ->
            tag.categoryId == categoryId && (tag.archivedAt == null || tag.id == tagId)
        }

    private val draft: EntryTemplateDraft
        get() = EntryTemplateDraft(
            name = name,
            type = type,
            amount = amount,
            categoryId = categoryId,
            tagId = tagId,
            walletId = walletId,
            memo = memo,
            billShift = if (billRecurring == null) 0 else billShift,
        )

    fun icon(of: Identifier<Icon>): Icon? = options?.icons?.get(of)

    suspend fun load() {
        try {
            options = database.entryOptions()
            cardBills = database.recurrings()

            if (categories.none { it.id == categoryId }) {
                select(category = categories.firstOrNull())
            }

            if (wallets.none { it.id == walletId }) {
                walletId = wallets.firstOrNull()?.id
                billShift = 0
            }
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "テンプレートを読めませんでした"
        }
    }

    fun select(category: EntryCategory?) {
        if (category?.id != categoryId) {
            tagId = null
        }

        categoryId = category?.id
        message = ""
    }

    fun select(wallet: Wallet) {
        if (wallet.id != walletId) {
            billShift = 0
        }

        walletId = wallet.id
        message = ""
    }

    fun toggleTag(id: Identifier<EntryTag>) {
        tagId = if (tagId == id) null else id
    }

    fun press(key: AmountCalculator.Key) {
        calculator = calculator.press(key)
        message = ""
    }

    suspend fun save(): EntryTemplate? {
        if (isSaving) {
            return null
        }

        val draft = draft
        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            message = message(of = problem)
            return null
        }

        isSaving = true

        try {
            return database.saveTemplate(
                draft = draft,
                at = Instant.now(),
            )
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "保存できませんでした"
            return null
        } finally {
            isSaving = false
        }
    }

    private fun message(of: EntryTemplateDraft.Problem): String = when (of) {
        EntryTemplateDraft.Problem.emptyName -> "名前を入れてください"
        EntryTemplateDraft.Problem.missingCategory -> "カテゴリを選んでください"
        EntryTemplateDraft.Problem.missingWallet -> "${walletTitle}を選んでください"
        else -> "保存できませんでした"
    }
}
