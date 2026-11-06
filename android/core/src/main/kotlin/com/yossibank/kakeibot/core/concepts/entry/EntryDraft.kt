package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import kotlinx.serialization.Serializable
import java.time.Instant

data class EntryDraft(
    val type: Entry.Kind,
    val amount: Int,
    val date: LocalDate,
    val categoryId: Identifier<EntryCategory>?,
    val tagId: Identifier<EntryTag>? = null,
    val templateId: Identifier<EntryTemplate>? = null,
    val walletId: Identifier<Wallet>,
    val toWalletId: Identifier<Wallet>? = null,
    val memo: String = "",
    val billMonth: YearMonth? = null,
    val fee: Int = 0,
    val items: List<EntryItem.Draft>? = null,
    val taxIncluded: Boolean = false,
) {
    constructor(entry: Entry) : this(
        type = entry.type,
        amount = entry.amount,
        date = entry.date,
        categoryId = entry.categoryId,
        tagId = entry.tagId,
        templateId = entry.templateId,
        walletId = entry.walletId,
        toWalletId = entry.toWalletId,
        memo = entry.memo ?: "",
        billMonth = entry.billMonth,
        taxIncluded = entry.taxIncluded,
    )

    @Serializable
    enum class Problem {
        amountNotPositive,
        missingCategory,
        categoryOnTransfer,
        missingDestination,
        sameWallet,
        tagWithoutCategory,
        feeNegative,
        feeOnNonTransfer,
        itemsOnTransfer,
        itemNameEmpty,
        itemQuantityNotPositive,
    }

    class ProblemException(
        val problem: Problem,
    ) : Exception(problem.name)

    val problems: List<Problem>
        get() {
            val amountProblems = if (amount < 1) listOf(Problem.amountNotPositive) else emptyList()

            val tagProblems = if (tagId != null && categoryId == null) {
                listOf(Problem.tagWithoutCategory)
            } else {
                emptyList()
            }

            return amountProblems + typeProblems + tagProblems + feeProblems + itemProblems
        }

    private val includesTax: Boolean
        get() = taxIncluded && !items.isNullOrEmpty()

    private val typeProblems: List<Problem>
        get() = when (type) {
            Entry.Kind.expense,
            Entry.Kind.income,
            -> if (categoryId == null) listOf(Problem.missingCategory) else emptyList()

            Entry.Kind.transfer -> {
                val categoryProblems = if (categoryId == null) emptyList() else listOf(Problem.categoryOnTransfer)

                categoryProblems + destinationProblems
            }
        }

    private val feeProblems: List<Problem>
        get() = when {
            fee < 0 -> listOf(Problem.feeNegative)
            fee >= 1 && type != Entry.Kind.transfer -> listOf(Problem.feeOnNonTransfer)
            else -> emptyList()
        }

    private val itemProblems: List<Problem>
        get() {
            val items = items ?: emptyList()

            val transferProblems = if (type == Entry.Kind.transfer && items.isNotEmpty()) {
                listOf(Problem.itemsOnTransfer)
            } else {
                emptyList()
            }

            val nameProblems = if (items.any { it.trimmedName.isEmpty() }) {
                listOf(Problem.itemNameEmpty)
            } else {
                emptyList()
            }

            val quantityProblems = if (items.any { it.quantity < 1 }) {
                listOf(Problem.itemQuantityNotPositive)
            } else {
                emptyList()
            }

            return transferProblems + nameProblems + quantityProblems
        }

    private val destinationProblems: List<Problem>
        get() {
            val toWalletId = toWalletId ?: return listOf(Problem.missingDestination)

            return if (toWalletId == walletId) listOf(Problem.sameWallet) else emptyList()
        }

    private val destination: Identifier<Wallet>?
        get() = if (type == Entry.Kind.transfer) toWalletId else null

    private val trimmedMemo: String?
        get() = memo.trim().ifEmpty { null }

    fun newEntry(at: Instant): Entry {
        validate()

        return Entry(
            type = type,
            amount = amount,
            date = date,
            categoryId = categoryId,
            tagId = tagId,
            templateId = templateId,
            walletId = walletId,
            toWalletId = destination,
            memo = trimmedMemo,
            billMonth = billMonth,
            taxIncluded = includesTax,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: Entry,
        at: Instant,
    ): Entry {
        validate()

        return to.copy(
            type = type,
            amount = amount,
            date = date,
            categoryId = categoryId,
            tagId = tagId,
            templateId = templateId,
            walletId = walletId,
            toWalletId = destination,
            memo = trimmedMemo,
            billMonth = billMonth,
            taxIncluded = if (items != null) includesTax else to.taxIncluded,
            updatedAt = at,
        )
    }

    private fun validate() {
        val problem = problems.firstOrNull() ?: return

        throw ProblemException(problem)
    }
}
