package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.clampedBillShift
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import kotlinx.serialization.Serializable
import java.time.Instant

data class EntryTemplateDraft(
    val name: String,
    val type: Entry.Kind,
    val amount: Int?,
    val categoryId: Identifier<EntryCategory>?,
    val tagId: Identifier<EntryTag>? = null,
    val walletId: Identifier<Wallet>?,
    val memo: String = "",
    val billShift: Int = 0,
) {
    constructor(template: EntryTemplate) : this(
        name = template.name,
        type = template.type,
        amount = template.amount,
        categoryId = template.categoryId,
        tagId = template.tagId,
        walletId = template.walletId,
        memo = template.memo ?: "",
        billShift = template.billShift,
    )

    @Serializable
    enum class Problem {
        emptyName,
        transfer,
        amountNotPositive,
        missingCategory,
        missingWallet,
    }

    class ProblemException(
        val problem: Problem,
    ) : Exception(problem.name)

    private data class Fields(
        val categoryId: Identifier<EntryCategory>,
        val walletId: Identifier<Wallet>,
    )

    val problems: List<Problem>
        get() {
            val problems = mutableListOf<Problem>()
            val amount = amount

            if (trimmedName.isEmpty()) {
                problems += Problem.emptyName
            }

            if (type == Entry.Kind.transfer) {
                problems += Problem.transfer
            }

            if (amount != null && amount < 1) {
                problems += Problem.amountNotPositive
            }

            if (categoryId == null) {
                problems += Problem.missingCategory
            }

            if (walletId == null) {
                problems += Problem.missingWallet
            }

            return problems
        }

    private val trimmedName: String
        get() = name.trim()

    private val trimmedMemo: String?
        get() = memo.trim().ifEmpty { null }

    fun newTemplate(
        sortOrder: Int,
        at: Instant,
    ): EntryTemplate {
        val fields = validated()

        return EntryTemplate(
            name = trimmedName,
            type = type,
            amount = amount,
            categoryId = fields.categoryId,
            tagId = tagId,
            walletId = fields.walletId,
            memo = trimmedMemo,
            billShift = Recurring.clampedBillShift(billShift),
            sortOrder = sortOrder,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: EntryTemplate,
        at: Instant,
    ): EntryTemplate {
        val fields = validated()

        return to.copy(
            name = trimmedName,
            type = type,
            amount = amount,
            categoryId = fields.categoryId,
            tagId = tagId,
            walletId = fields.walletId,
            memo = trimmedMemo,
            billShift = Recurring.clampedBillShift(billShift),
            updatedAt = at,
        )
    }

    private fun validated(): Fields {
        problems.firstOrNull()?.let {
            throw ProblemException(it)
        }

        val categoryId = categoryId ?: throw ProblemException(Problem.missingCategory)
        val walletId = walletId ?: throw ProblemException(Problem.missingCategory)

        return Fields(
            categoryId = categoryId,
            walletId = walletId,
        )
    }
}
