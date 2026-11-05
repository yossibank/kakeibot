package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class WalletDraft(
    val kind: Wallet.Kind,
    val name: String,
    val mark: IconDraft.Mark,
    val color: String,
    val initialBalance: Int,
    val loanAmount: Int? = null,
    val recordedKind: Wallet.Kind? = null,
    val hasValuations: Boolean = false,
) {
    constructor(
        wallet: Wallet,
        icon: Icon,
    ) : this(
        kind = wallet.kind,
        name = wallet.name,
        mark = IconDraft.Mark.of(icon),
        color = icon.color,
        initialBalance = wallet.initialBalance,
        loanAmount = wallet.loanAmount,
    )

    val icon: IconDraft
        get() = IconDraft(
            mark = mark,
            color = color,
        )

    val problems: List<DraftProblem>
        get() {
            val nameProblems = if (trimmedName.isEmpty()) listOf(DraftProblem.emptyName) else emptyList()

            return nameProblems + icon.problems + kindProblems
        }

    private val kindProblems: List<DraftProblem>
        get() {
            val recordedKind = recordedKind ?: return emptyList()

            if (recordedKind.isDebt != kind.isDebt) {
                return listOf(DraftProblem.kindLocked)
            }

            if (hasValuations &&
                recordedKind == Wallet.Kind.investment &&
                kind != Wallet.Kind.investment
            ) {
                return listOf(DraftProblem.valuedKindLocked)
            }

            return emptyList()
        }

    private val trimmedName: String
        get() = name.trim()

    private val savedLoanAmount: Int?
        get() {
            val loanAmount = loanAmount

            if (kind != Wallet.Kind.loan || loanAmount == null || loanAmount <= 0) {
                return null
            }

            return loanAmount
        }

    fun locked(
        by: Wallet,
        hasRecords: Boolean,
        hasValuations: Boolean,
    ): WalletDraft = copy(
        recordedKind = if (hasRecords) by.kind else null,
        hasValuations = hasValuations,
    )

    fun newIcon(at: Instant): Icon {
        validate()

        return icon.newIcon(at)
    }

    fun newWallet(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): Wallet {
        validate()

        return Wallet(
            name = trimmedName,
            kind = kind,
            iconId = iconId,
            initialBalance = initialBalance,
            loanAmount = savedLoanAmount,
            sortOrder = sortOrder,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: Icon,
        at: Instant,
    ): Icon {
        validate()

        return icon.applied(
            to = to,
            at = at,
        )
    }

    fun applied(
        to: Wallet,
        at: Instant,
    ): Wallet {
        validate()

        return to.copy(
            name = trimmedName,
            kind = kind,
            initialBalance = initialBalance,
            loanAmount = savedLoanAmount,
            updatedAt = at,
        )
    }

    private fun validate() {
        val problem = problems.firstOrNull() ?: return

        throw DraftProblemException(problem)
    }
}
