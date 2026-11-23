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
import com.yossibank.kakeibot.features.shared.model.ModelTask
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.saveTemplate
import java.time.Instant

class TemplateEditModel(
    private val database: AppDatabase,
    draft: EntryTemplateDraft,
) {
    var form: EntryTemplateDraft by mutableStateOf(draft)
        private set

    var calculator: AmountCalculator by mutableStateOf(AmountCalculator(amount = draft.amount ?: 0))
        private set

    private var options: EntryOptions? by mutableStateOf(null)
    private var cardBills: List<Recurring> by mutableStateOf(emptyList())

    private val task = ModelTask()

    val message: String
        get() = task.message

    val billRecurring: Recurring?
        get() = cardBills.cardBill(paidBy = form.walletId)

    val category: EntryCategory?
        get() = categories.firstOrNull { it.id == form.categoryId }

    val wallet: Wallet?
        get() = wallets.firstOrNull { it.id == form.walletId }

    val tag: EntryTag?
        get() = tags.firstOrNull { it.id == form.tagId }

    val detail: String
        get() = listOfNotNull(category?.name, tag?.name, wallet?.name).joinToString("・")

    val amount: Int?
        get() = calculator.amount.takeIf { it > 0 }

    val walletTitle: String
        get() = if (form.type == Entry.Kind.income) "入金先" else "支払い元"

    val categories: List<EntryCategory>
        get() = when (form.type) {
            Entry.Kind.income -> options?.incomeCategories ?: emptyList()
            else -> options?.expenseCategories ?: emptyList()
        }

    val wallets: List<Wallet>
        get() = options?.wallets ?: emptyList()

    val tags: List<EntryTag>
        get() = (options?.tags ?: emptyList()).filter { tag ->
            tag.categoryId == form.categoryId && (tag.archivedAt == null || tag.id == form.tagId)
        }

    private val draft: EntryTemplateDraft
        get() = form.copy(
            amount = amount,
            billShift = if (billRecurring == null) 0 else form.billShift,
        )

    fun icon(of: Identifier<Icon>): Icon? = options?.icons?.get(of)

    fun update(change: EntryTemplateDraft.() -> EntryTemplateDraft) {
        form = form.change()
    }

    suspend fun load() {
        task.attempt(failure = "テンプレートを読めませんでした") {
            options = database.entryOptions()
            cardBills = database.recurrings()

            if (categories.none { it.id == form.categoryId }) {
                form = form.withCategory(categories.firstOrNull()?.id)
            }

            if (wallets.none { it.id == form.walletId }) {
                form = form.copy(
                    walletId = wallets.firstOrNull()?.id,
                    billShift = 0,
                )
            }
        }
    }

    fun select(category: EntryCategory?) {
        form = form.withCategory(category?.id)
        task.clear()
    }

    fun select(wallet: Wallet) {
        form = form.withWallet(wallet.id)
        task.clear()
    }

    fun toggleTag(id: Identifier<EntryTag>) {
        form = form.copy(tagId = if (form.tagId == id) null else id)
    }

    fun press(key: AmountCalculator.Key) {
        calculator = calculator.press(key)
        task.clear()
    }

    suspend fun save(): EntryTemplate? {
        if (task.isRunning) {
            return null
        }

        val draft = draft
        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            task.show(message(of = problem))
            return null
        }

        return task.attempt(failure = ModelTask.saveFailed) {
            database.saveTemplate(
                draft = draft,
                at = Instant.now(),
            )
        }
    }

    private fun message(of: EntryTemplateDraft.Problem): String = when (of) {
        EntryTemplateDraft.Problem.emptyName -> "名前を入れてください"
        EntryTemplateDraft.Problem.missingCategory -> "カテゴリを選んでください"
        EntryTemplateDraft.Problem.missingWallet -> "${walletTitle}を選んでください"
        else -> ModelTask.saveFailed
    }
}

private fun EntryTemplateDraft.withCategory(id: Identifier<EntryCategory>?): EntryTemplateDraft {
    if (id == categoryId) {
        return this
    }

    return copy(
        categoryId = id,
        tagId = null,
    )
}

private fun EntryTemplateDraft.withWallet(id: Identifier<Wallet>?): EntryTemplateDraft {
    if (id == walletId) {
        return this
    }

    return copy(
        walletId = id,
        billShift = 0,
    )
}
