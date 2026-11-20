package com.yossibank.kakeibot.features.screens.entry.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.billMonth
import com.yossibank.kakeibot.core.concepts.recurring.cardBill
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.date.shortName
import com.yossibank.kakeibot.designsystem.components.input.symbol
import com.yossibank.kakeibot.designsystem.components.text.AmountText
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
import com.yossibank.kakeibot.store.writes.methods.WriteError
import com.yossibank.kakeibot.store.writes.methods.WriteException
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.entryItems
import com.yossibank.kakeibot.store.writes.methods.fee
import com.yossibank.kakeibot.store.writes.methods.recentItemNames
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import kotlinx.coroutines.CancellationException
import java.time.Instant

class EntryModel(
    private val database: AppDatabase,
    val today: LocalDate,
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

    var type: Entry.Kind by mutableStateOf(Entry.Kind.expense)
        private set

    var calculator: AmountCalculator by mutableStateOf(AmountCalculator())
        internal set

    var feeCalculator: AmountCalculator by mutableStateOf(AmountCalculator())
        private set

    var date: LocalDate by mutableStateOf(today)
        internal set

    var categoryId: Identifier<EntryCategory>? by mutableStateOf(null)
        internal set

    var tagId: Identifier<EntryTag>? by mutableStateOf(null)
        internal set

    var walletId: Identifier<Wallet>? by mutableStateOf(null)
        internal set

    var toWalletId: Identifier<Wallet>? by mutableStateOf(null)
        internal set

    var memo: String by mutableStateOf("")

    var field: Field by mutableStateOf(Field.Amount)
        private set

    var message: String? by mutableStateOf(null)
        private set

    var isSaving: Boolean by mutableStateOf(false)
        private set

    var history: EntryList? by mutableStateOf(null)
        private set

    var items: List<EntryItem.Draft> by mutableStateOf(emptyList())
        internal set

    var taxIncluded: Boolean by mutableStateOf(false)
        internal set

    var recentItemNames: List<String> by mutableStateOf(emptyList())
        private set

    var recentMemos: List<String> by mutableStateOf(emptyList())
        private set

    var voiceFilled: VoiceFilled? by mutableStateOf(null)
        internal set

    private var options: EntryOptions? by mutableStateOf(null)
    private var allTemplates: List<EntryTemplate> by mutableStateOf(emptyList())
    private var cardBills: List<Recurring> = emptyList()
    private var appliedTemplateId: Identifier<EntryTemplate>? by mutableStateOf(null)
    internal var billMonth: YearMonth? by mutableStateOf(null)

    val isEditing: Boolean
        get() = editing != null

    internal val editingId: Identifier<Entry>?
        get() = editing

    val isBlank: Boolean
        get() = !isEditing && amount <= 0

    val startField: Field
        get() = if (type == Entry.Kind.transfer) Field.Transfer else Field.Category

    val showsRecent: Boolean
        get() = isBlank && this.field == startField

    val amount: Int
        get() = calculator.amount

    val fee: Int
        get() = if (type == Entry.Kind.transfer) feeCalculator.amount else 0

    val activeCalculator: AmountCalculator
        get() = if (this.field == Field.Fee) feeCalculator else calculator

    val templates: List<EntryTemplate>
        get() = allTemplates.filter { it.type == type }

    val tags: List<EntryTag>
        get() = allTags.filter { tag ->
            tag.categoryId == categoryId && (tag.archivedAt == null || tag.id == tagId)
        }

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
            val calculator = activeCalculator
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

    internal val allTags: List<EntryTag>
        get() = (options?.tags ?: emptyList()) + (options?.sharedTags ?: emptyList())

    private val allCategories: List<EntryCategory>
        get() = (options?.expenseCategories ?: emptyList()) +
            (options?.incomeCategories ?: emptyList()) +
            (options?.sharedCategories ?: emptyList())

    fun icon(of: Identifier<Icon>): Icon? = options?.icons?.get(of)

    fun category(of: Identifier<EntryCategory>?): EntryCategory? =
        allCategories.firstOrNull { it.id == of }

    fun wallet(of: Identifier<Wallet>?): Wallet? = wallets.firstOrNull { it.id == of }

    suspend fun load() {
        try {
            database.insertDefaultsIfEmpty(at = Instant.now())

            val loaded = database.entryOptions()

            allTemplates = database.templates()
            cardBills =
                database.recurrings().filter {
                    it.type == Entry.Kind.transfer &&
                        it.closingDay != null
                }
            recentItemNames = database.recentItemNames(limit = RECENT_ITEM_NAME_LIMIT)
            recentMemos = database.recentMemos(limit = RECENT_MEMO_LIMIT)
            history = database.entryList()

            val entry = loadEntry()

            options = loaded

            if (entry != null) {
                type = entry.type
                calculator = AmountCalculator(amount = entry.amount)
                feeCalculator = AmountCalculator(amount = database.fee(of = entry.id)?.amount ?: 0)
                date = entry.date
                categoryId = entry.categoryId
                tagId = entry.tagId
                walletId = entry.walletId
                toWalletId = entry.toWalletId
                memo = entry.memo ?: ""
                appliedTemplateId = entry.templateId
                billMonth = entry.billMonth
                items = database.entryItems(of = entry.id).map { EntryItem.Draft(it) }
                taxIncluded = entry.taxIncluded
            } else {
                categoryId = categories.firstOrNull()?.id
                walletId = loaded.wallets.firstOrNull()?.id
            }

            field = startField
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "読み込めませんでした"
        }
    }

    fun focus(field: Field) {
        val isTransferOnly = field == Field.Fee || field == Field.Transfer
        this.field = if (isTransferOnly && type != Entry.Kind.transfer) Field.Amount else field
    }

    fun select(type: Entry.Kind) {
        if (this.type == type) {
            return
        }

        this.type = type

        categoryId = categories.firstOrNull()?.id
        tagId = null
        toWalletId = if (type == Entry.Kind.transfer) {
            toWalletId ?: wallets.firstOrNull { it.id != walletId }?.id
        } else {
            null
        }

        field = startField

        message = null
    }

    fun select(category: EntryCategory) {
        if (category.id != categoryId) {
            tagId = null
        }

        categoryId = category.id
        field = Field.Amount
        message = null
    }

    fun toggleTag(id: Identifier<EntryTag>) {
        tagId = if (tagId == id) null else id
    }

    fun select(wallet: Wallet) {
        if (wallet.id != walletId) {
            billMonth = null
        }

        walletId = wallet.id
        field = if (type == Entry.Kind.transfer) Field.Transfer else Field.Amount
    }

    fun selectDestination(wallet: Wallet) {
        toWalletId = wallet.id
        field = Field.Transfer
        message = null
    }

    fun swapWallets() {
        val source = walletId
        walletId = toWalletId
        toWalletId = source
        billMonth = null
        message = null
    }

    fun select(date: LocalDate) {
        if (date != this.date) {
            billMonth = null
        }

        this.date = date
        field = Field.Amount
    }

    fun press(key: AmountCalculator.Key) {
        if (field == Field.Fee) {
            feeCalculator = feeCalculator.press(key)
        } else {
            calculator = calculator.press(key)
        }

        message = null
    }

    fun setFee(amount: Int) {
        feeCalculator = AmountCalculator(amount = amount)
    }

    fun apply(template: EntryTemplate) {
        select(template.type)

        categoryId = template.categoryId
        tagId = allTags.firstOrNull { it.id == template.tagId && it.archivedAt == null }?.id
        walletId = template.walletId
        appliedTemplateId = template.id
        billMonth = cardBills
            .cardBill(paidBy = template.walletId)
            ?.billMonth(used = date, shift = template.billShift)

        template.memo?.takeIf { it.isNotEmpty() }?.let { memo = it }
        template.amount?.let { calculator = AmountCalculator(amount = it) }

        field = Field.Amount
        message = null
    }

    fun applyRecent(entry: Entry) {
        wallet(of = entry.walletId)?.let { wallet ->
            select(wallet = wallet)
        }

        if (categories.any { it.id == entry.categoryId }) {
            categoryId = entry.categoryId
        }

        tagId = allTags.firstOrNull { it.id == entry.tagId && it.archivedAt == null }?.id

        entry.memo?.takeIf { it.isNotEmpty() }?.let { memo = it }
        calculator = AmountCalculator(amount = entry.amount)

        field = Field.Amount
        message = null
    }

    fun applyTransfer(entry: Entry) {
        walletId = entry.walletId
        toWalletId = entry.toWalletId
        calculator = AmountCalculator(amount = entry.amount)
        feeCalculator = AmountCalculator(amount = fee(of = entry))
        billMonth = null

        field = Field.Amount
        message = null
    }

    suspend fun save(): Boolean {
        val walletId = walletId

        if (walletId == null || isSaving) {
            return false
        }

        val templateId = allTemplates
            .firstOrNull { it.id == appliedTemplateId && it.type == type }
            ?.id

        val draft = EntryDraft(
            type = type,
            amount = amount,
            date = date,
            categoryId = categoryId,
            tagId = tagId,
            templateId = templateId,
            walletId = walletId,
            toWalletId = toWalletId,
            memo = memo,
            billMonth = billMonth,
            fee = fee,
            items = if (showsItems) items else emptyList(),
            taxIncluded = taxIncluded,
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

    suspend fun startNext() {
        calculator = AmountCalculator()
        feeCalculator = AmountCalculator()
        memo = ""
        tagId = null
        appliedTemplateId = null
        billMonth = null
        items = emptyList()
        taxIncluded = false
        voiceFilled = null
        field = startField
        message = null

        try {
            history = database.entryList()
            recentItemNames = database.recentItemNames(limit = RECENT_ITEM_NAME_LIMIT)
            recentMemos = database.recentMemos(limit = RECENT_MEMO_LIMIT)
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "読み込めませんでした"
        }
    }

    fun newTemplateDraft(): EntryTemplateDraft = EntryTemplateDraft(
        name = "",
        type = if (type == Entry.Kind.income) Entry.Kind.income else Entry.Kind.expense,
        amount = amount.takeIf { it > 0 },
        categoryId = categoryId,
        tagId = tagId,
        walletId = walletId,
        memo = memo,
    )

    suspend fun reloadTemplates() {
        try {
            allTemplates = database.templates()
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = "読み込めませんでした"
        }
    }

    private suspend fun loadEntry(): Entry? {
        val entry = editing?.let { database.entry(it) } ?: return null
        val transferId = entry.transferId ?: return entry
        val transfer = database.entry(transferId) ?: return entry

        editing = transfer.id

        return transfer
    }

    private fun message(of: EntryDraft.Problem): String = when (of) {
        EntryDraft.Problem.amountNotPositive -> "金額を入れてください"
        EntryDraft.Problem.missingCategory -> "カテゴリを選んでください"
        EntryDraft.Problem.missingDestination -> "振替先を選んでください"
        EntryDraft.Problem.sameWallet -> "振替元と振替先を別にしてください"
        else -> "保存できませんでした"
    }
}
