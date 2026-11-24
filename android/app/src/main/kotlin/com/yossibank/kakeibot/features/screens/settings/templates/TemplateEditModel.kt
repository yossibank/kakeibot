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
import com.yossibank.kakeibot.features.shared.model.ScreenClock
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.saveTemplate

class TemplateEditModel(
    database: AppDatabase,
    clock: ScreenClock,
    draft: EntryTemplateDraft,
) {
    val state = State(draft)
    val input = Input()
    val output = Output(input, state)

    private val dependencies = Dependencies(database, clock)

    class State(
        draft: EntryTemplateDraft,
    ) {
        val task = ModelTask()

        var form: EntryTemplateDraft by mutableStateOf(draft)
            private set

        var calculator: AmountCalculator by mutableStateOf(
            AmountCalculator(
                amount =
                    draft.amount ?: 0,
            ),
        )
            private set

        fun update(change: EntryTemplateDraft.() -> EntryTemplateDraft) {
            form = form.change()
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
    }

    class Input {
        var options: EntryOptions? by mutableStateOf(null)
            internal set

        var cardBills: List<Recurring> by mutableStateOf(emptyList())
            internal set
    }

    class Output(
        private val input: Input,
        private val state: State,
    ) {
        val billRecurring: Recurring?
            get() = input.cardBills.cardBill(paidBy = state.form.walletId)

        val category: EntryCategory?
            get() = categories.firstOrNull { it.id == state.form.categoryId }

        val wallet: Wallet?
            get() = wallets.firstOrNull { it.id == state.form.walletId }

        val tag: EntryTag?
            get() = tags.firstOrNull { it.id == state.form.tagId }

        val detail: String
            get() = listOfNotNull(category?.name, tag?.name, wallet?.name).joinToString("・")

        val amount: Int?
            get() = state.calculator.amount.takeIf { it > 0 }

        val walletTitle: String
            get() = if (state.form.type == Entry.Kind.income) "入金先" else "支払い元"

        val categories: List<EntryCategory>
            get() = when (state.form.type) {
                Entry.Kind.income -> input.options?.incomeCategories ?: emptyList()
                else -> input.options?.expenseCategories ?: emptyList()
            }

        val wallets: List<Wallet>
            get() = input.options?.wallets ?: emptyList()

        val tags: List<EntryTag>
            get() = (input.options?.tags ?: emptyList()).filter { tag ->
                tag.categoryId == state.form.categoryId &&
                    (tag.archivedAt == null || tag.id == state.form.tagId)
            }

        val draft: EntryTemplateDraft
            get() = state.form.copy(
                amount = amount,
                billShift = if (billRecurring == null) 0 else state.form.billShift,
            )

        fun icon(of: Identifier<Icon>): Icon? = input.options?.icons?.get(of)

        fun message(of: EntryTemplateDraft.Problem): String = when (of) {
            EntryTemplateDraft.Problem.emptyName -> "名前を入れてください"
            EntryTemplateDraft.Problem.missingCategory -> "カテゴリを選んでください"
            EntryTemplateDraft.Problem.missingWallet -> "${walletTitle}を選んでください"
            else -> ModelTask.saveFailed
        }
    }

    private class Dependencies(
        val database: AppDatabase,
        val clock: ScreenClock,
    )

    suspend fun load() {
        state.task.attempt(failure = "テンプレートを読めませんでした") {
            input.options = dependencies.database.entryOptions()
            input.cardBills = dependencies.database.recurrings()

            if (output.categories.none { it.id == state.form.categoryId }) {
                state.update { withCategory(output.categories.firstOrNull()?.id) }
            }

            if (output.wallets.none { it.id == state.form.walletId }) {
                state.update {
                    copy(
                        walletId = output.wallets.firstOrNull()?.id,
                        billShift = 0,
                    )
                }
            }
        }
    }

    suspend fun save(): EntryTemplate? {
        if (state.task.isRunning) {
            return null
        }

        val draft = output.draft
        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            state.task.show(output.message(of = problem))
            return null
        }

        return state.task.attempt(failure = ModelTask.saveFailed) {
            dependencies.database.saveTemplate(
                draft = draft,
                at = dependencies.clock.now,
            )
        }
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
