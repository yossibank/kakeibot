package com.yossibank.kakeibot.features.screens.entry.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.features.shared.model.ModelTask
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entry
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recentMemos
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.methods.templates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.EntryWriteError
import com.yossibank.kakeibot.store.writes.methods.EntryWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.entryItems
import com.yossibank.kakeibot.store.writes.methods.fee
import com.yossibank.kakeibot.store.writes.methods.recentItemNames
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import java.time.Instant

class EntryModel(
    private val database: AppDatabase,
    today: LocalDate,
    private var editing: Identifier<Entry>? = null,
) {
    enum class Field {
        Category,
        Wallet,
        ToWallet,
        Date,
        Amount,
        Fee,
        Transfer,
    }

    var today: LocalDate by mutableStateOf(today)

    var form: EntryForm by mutableStateOf(EntryForm(date = today))
        private set

    var calculator: AmountCalculator by mutableStateOf(AmountCalculator())
        private set

    var feeCalculator: AmountCalculator by mutableStateOf(AmountCalculator())
        private set

    var field: Field by mutableStateOf(Field.Amount)
        private set

    var history: EntryList? by mutableStateOf(null)
        private set

    var recentItemNames: List<String> by mutableStateOf(emptyList())
        private set

    var recentMemos: List<String> by mutableStateOf(emptyList())
        private set

    var voiceFilled: VoiceFilled? by mutableStateOf(null)
        private set

    internal var cardBills: List<Recurring> = emptyList()
        private set

    private var options: EntryOptions? by mutableStateOf(null)
    private var allTemplates: List<EntryTemplate> by mutableStateOf(emptyList())

    private val task = ModelTask()

    val message: String
        get() = task.message

    val isEditing: Boolean
        get() = editing != null

    val isBlank: Boolean
        get() = !isEditing && amount <= 0

    val startField: Field
        get() = if (form.type == Entry.Kind.transfer) Field.Transfer else Field.Category

    val showsRecent: Boolean
        get() = isBlank && this.field == startField

    val amount: Int
        get() = calculator.amount

    val fee: Int
        get() = if (form.type == Entry.Kind.transfer) feeCalculator.amount else 0

    val activeCalculator: AmountCalculator
        get() = if (this.field == Field.Fee) feeCalculator else calculator

    val templates: List<EntryTemplate>
        get() = allTemplates.filter { it.type == form.type }

    val tags: List<EntryTag>
        get() = allTags.filter { tag ->
            tag.categoryId == form.categoryId && (tag.archivedAt == null || tag.id == form.tagId)
        }

    val categories: List<EntryCategory>
        get() = when (form.type) {
            Entry.Kind.expense -> options?.expenseCategories ?: emptyList()
            Entry.Kind.income -> options?.incomeCategories ?: emptyList()
            Entry.Kind.transfer -> emptyList()
        }

    val wallets: List<Wallet>
        get() = options?.wallets ?: emptyList()

    val category: EntryCategory?
        get() = categories.firstOrNull { it.id == form.categoryId }

    val wallet: Wallet?
        get() = wallets.firstOrNull { it.id == form.walletId }

    val toWallet: Wallet?
        get() = wallets.firstOrNull { it.id == form.toWalletId }

    internal val editingId: Identifier<Entry>?
        get() = editing

    internal val allTags: List<EntryTag>
        get() = (options?.tags ?: emptyList()) + (options?.sharedTags ?: emptyList())

    private val allCategories: List<EntryCategory>
        get() = (options?.expenseCategories ?: emptyList()) +
            (options?.incomeCategories ?: emptyList()) +
            (options?.sharedCategories ?: emptyList())

    private val draft: EntryDraft?
        get() = form.draft(
            amount = amount,
            fee = fee,
            templates = allTemplates,
            includesItems = showsItems,
        )

    fun icon(of: Identifier<Icon>): Icon? = options?.icons?.get(of)

    fun category(of: Identifier<EntryCategory>?): EntryCategory? =
        allCategories.firstOrNull { it.id == of }

    fun wallet(of: Identifier<Wallet>?): Wallet? = wallets.firstOrNull { it.id == of }

    fun update(change: EntryForm.() -> EntryForm) {
        form = form.change()
    }

    fun focus(field: Field) {
        val isTransferOnly = field == Field.Fee || field == Field.Transfer
        this.field = if (isTransferOnly && form.type != Entry.Kind.transfer) Field.Amount else field
    }

    fun clearMessage() {
        task.clear()
    }

    fun select(type: Entry.Kind) {
        if (form.type == type) {
            return
        }

        form = form.copy(type = type)

        val destination = if (type == Entry.Kind.transfer) {
            form.toWalletId ?: wallets.firstOrNull { it.id != form.walletId }?.id
        } else {
            null
        }

        form = form.copy(
            categoryId = categories.firstOrNull()?.id,
            tagId = null,
            toWalletId = destination,
        )

        field = startField

        task.clear()
    }

    fun select(category: EntryCategory) {
        form = form.withCategory(category.id)
        field = Field.Amount

        task.clear()
    }

    fun toggleTag(id: Identifier<EntryTag>) {
        form = form.copy(tagId = if (form.tagId == id) null else id)
    }

    fun select(wallet: Wallet) {
        form = form.withWallet(wallet.id)
        field = if (form.type == Entry.Kind.transfer) Field.Transfer else Field.Amount
    }

    fun selectDestination(wallet: Wallet) {
        form = form.copy(toWalletId = wallet.id)
        field = Field.Transfer

        task.clear()
    }

    fun swapWallets() {
        form = form.copy(
            walletId = form.toWalletId,
            toWalletId = form.walletId,
            billMonth = null,
        )

        task.clear()
    }

    fun select(date: LocalDate) {
        form = form.withDate(date)
        field = Field.Amount
    }

    fun press(key: AmountCalculator.Key) {
        if (field == Field.Fee) {
            feeCalculator = feeCalculator.press(key)
        } else {
            calculator = calculator.press(key)
        }

        task.clear()
    }

    fun setAmount(amount: Int) {
        calculator = AmountCalculator(amount = amount)
    }

    fun setFee(amount: Int) {
        feeCalculator = AmountCalculator(amount = amount)
    }

    suspend fun load() {
        task.attempt(failure = ModelTask.loadFailed) {
            database.insertDefaultsIfEmpty(at = Instant.now())

            val loaded = database.entryOptions()

            allTemplates = database.templates()
            cardBills = database.recurrings().filter { recurring ->
                recurring.type == Entry.Kind.transfer && recurring.closingDay != null
            }

            loadHistory()

            val entry = loadEntry()

            options = loaded

            if (entry != null) {
                val items = database.entryItems(of = entry.id).map { EntryItem.Draft(it) }

                form = EntryForm.of(
                    entry = entry,
                    items = items,
                )
                calculator = AmountCalculator(amount = entry.amount)
                feeCalculator = AmountCalculator(amount = database.fee(of = entry.id)?.amount ?: 0)
            } else {
                form = form.copy(
                    categoryId = categories.firstOrNull()?.id,
                    walletId = loaded.wallets.firstOrNull()?.id,
                )
            }

            field = startField
        }
    }

    suspend fun save(): Boolean {
        val draft = draft

        if (draft == null || task.isRunning) {
            return false
        }

        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            task.show(message(of = problem))
            return false
        }

        val saved = task.attempt(describe = ::saveFailure) {
            database.saveEntry(
                draft = draft,
                editing = editing,
                at = Instant.now(),
            )
        }

        return saved != null
    }

    suspend fun delete(): Boolean {
        val editing = editing

        if (editing == null || task.isRunning) {
            return false
        }

        val deleted = task.attempt(failure = "削除できませんでした") {
            database.deleteEntry(
                id = editing,
                at = Instant.now(),
            )
        }

        return deleted != null
    }

    suspend fun startNext() {
        form = form.cleared()
        calculator = AmountCalculator()
        feeCalculator = AmountCalculator()
        voiceFilled = null
        field = startField

        task.attempt(failure = ModelTask.loadFailed) {
            loadHistory()
        }
    }

    suspend fun reloadTemplates() {
        task.attempt(failure = ModelTask.loadFailed) {
            allTemplates = database.templates()
        }
    }

    internal fun fill(
        form: EntryForm,
        calculator: AmountCalculator,
        voiceFilled: VoiceFilled?,
    ) {
        this.form = form
        this.calculator = calculator
        this.voiceFilled = voiceFilled
    }

    private suspend fun loadHistory() {
        recentItemNames = database.recentItemNames(limit = RECENT_ITEM_NAME_LIMIT)
        recentMemos = database.recentMemos(limit = RECENT_MEMO_LIMIT)
        history = database.entryList()
    }

    private suspend fun loadEntry(): Entry? {
        val entry = editing?.let { database.entry(it) } ?: return null
        val transferId = entry.transferId ?: return entry
        val transfer = database.entry(transferId) ?: return entry

        editing = transfer.id

        return transfer
    }

    private fun saveFailure(error: Exception): String {
        val isMissing = (error as? EntryWriteException)?.error == EntryWriteError.entryNotFound
        return if (isMissing) "記録が見つかりませんでした" else ModelTask.saveFailed
    }

    private fun message(of: EntryDraft.Problem): String = when (of) {
        EntryDraft.Problem.amountNotPositive -> "金額を入れてください"
        EntryDraft.Problem.missingCategory -> "カテゴリを選んでください"
        EntryDraft.Problem.missingDestination -> "振替先を選んでください"
        EntryDraft.Problem.sameWallet -> "振替元と振替先を別にしてください"
        else -> ModelTask.saveFailed
    }
}
