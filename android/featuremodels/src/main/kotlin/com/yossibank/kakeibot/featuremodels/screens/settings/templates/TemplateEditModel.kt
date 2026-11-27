package com.yossibank.kakeibot.featuremodels.screens.settings.templates

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
import com.yossibank.kakeibot.featuremodels.shared.model.EditFlow
import com.yossibank.kakeibot.featuremodels.shared.model.EditFlowSource
import com.yossibank.kakeibot.featuremodels.shared.model.ErrorNotice
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenEditable
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenWait
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.saveTemplate

class TemplateEditModel(
    parts: ScreenParts,
    draft: EntryTemplateDraft,
) : ScreenPerforming {
    val state = State(draft, parts.wait)
    val input = Input()
    val output = Output(input, state)
    val flow = EditFlow(task = state.task, source = Source())

    private val dependencies = Dependencies(parts.database, parts.clock)

    class Notices(
        wait: ScreenWait,
    ) {
        val error = ErrorNotice(wait)
    }

    class Submodels(
        amount: Int,
    ) {
        var calculator: AmountCalculator by mutableStateOf(AmountCalculator(amount = amount))
            internal set
    }

    data class Fields(
        val form: EntryTemplateDraft,
    ) : ScreenEditable

    class State(
        draft: EntryTemplateDraft,
        wait: ScreenWait,
    ) {
        val notices = Notices(wait)
        val task = ModelTask(notices.error)
        val submodels = Submodels(amount = draft.amount ?: 0)

        var fields: Fields by mutableStateOf(Fields(form = draft))
            private set

        fun update(change: EntryTemplateDraft.() -> EntryTemplateDraft) {
            fields = fields.copy(form = fields.form.change())
        }

        fun select(category: EntryCategory?) {
            update { withCategory(category?.id) }
        }

        fun select(wallet: Wallet) {
            update { withWallet(wallet.id) }
        }

        fun toggleTag(id: Identifier<EntryTag>) {
            update { copy(tagId = if (tagId == id) null else id) }
        }

        fun press(key: AmountCalculator.Key) {
            submodels.calculator = submodels.calculator.press(key)
        }
    }

    class Input {
        var options: EntryOptions? by mutableStateOf(null)
            internal set

        var cardBills: List<Recurring> by mutableStateOf(emptyList())
            internal set

        var baseline: EntryTemplateDraft? by mutableStateOf(null)
            internal set
    }

    class Output(
        private val input: Input,
        private val state: State,
    ) {
        val billRecurring: Recurring?
            get() = input.cardBills.cardBill(paidBy = state.fields.form.walletId)

        val category: EntryCategory?
            get() = categories.firstOrNull { it.id == state.fields.form.categoryId }

        val wallet: Wallet?
            get() = wallets.firstOrNull { it.id == state.fields.form.walletId }

        val tag: EntryTag?
            get() = tags.firstOrNull { it.id == state.fields.form.tagId }

        val detail: String
            get() = listOfNotNull(category?.name, tag?.name, wallet?.name).joinToString("・")

        val amount: Int?
            get() = state.submodels.calculator.amount.takeIf { it > 0 }

        val walletTitle: String
            get() = if (state.fields.form.type == Entry.Kind.income) "入金先" else "支払い元"

        val categories: List<EntryCategory>
            get() = when (state.fields.form.type) {
                Entry.Kind.income -> input.options?.incomeCategories ?: emptyList()
                else -> input.options?.expenseCategories ?: emptyList()
            }

        val wallets: List<Wallet>
            get() = input.options?.wallets ?: emptyList()

        val tags: List<EntryTag>
            get() = (input.options?.tags ?: emptyList()).filter { tag ->
                tag.categoryId == state.fields.form.categoryId &&
                    (tag.archivedAt == null || tag.id == state.fields.form.tagId)
            }

        val draft: EntryTemplateDraft
            get() = state.fields.form.copy(
                amount = amount,
                billShift = if (billRecurring == null) 0 else state.fields.form.billShift,
            )

        val problemMessage: String?
            get() = draft.problems.firstOrNull()?.let(::message)

        fun icon(of: Identifier<Icon>): Icon? = input.options?.icons?.get(of)

        private fun message(of: EntryTemplateDraft.Problem): String = when (of) {
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

    private inner class Source : EditFlowSource<EntryTemplate> {
        override val isEditing: Boolean = false

        override val isChanged: Boolean
            get() = input.baseline?.let { it != output.draft } ?: false

        override val problem: String?
            get() = output.problemMessage

        override suspend fun store(): EntryTemplate? {
            val draft = output.draft

            return state.task.attempt(failure = ModelTask.saveFailed) {
                dependencies.database.saveTemplate(
                    draft = draft,
                    at = dependencies.clock.now,
                )
            }
        }
    }

    suspend fun load() {
        state.task.attempt(failure = "テンプレートを読めませんでした") {
            input.options = dependencies.database.entryOptions()
            input.cardBills = dependencies.database.recurrings()

            if (output.categories.none { it.id == state.fields.form.categoryId }) {
                state.update { withCategory(output.categories.firstOrNull()?.id) }
            }

            if (output.wallets.none { it.id == state.fields.form.walletId }) {
                state.update {
                    copy(
                        walletId = output.wallets.firstOrNull()?.id,
                        billShift = 0,
                    )
                }
            }

            input.baseline = output.draft
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
