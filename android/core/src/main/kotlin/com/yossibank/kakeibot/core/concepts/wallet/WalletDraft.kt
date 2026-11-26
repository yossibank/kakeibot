package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.IconHoldingDraft
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
) : IconHoldingDraft<Wallet> {
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

    override fun newValue(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): Wallet = newWallet(
        iconId = iconId,
        sortOrder = sortOrder,
        at = at,
    )

    override fun applied(
        to: Wallet,
        at: Instant,
    ): Wallet {
        validateProblems()

        return to.copy(
            name = trimmedName,
            kind = kind,
            initialBalance = initialBalance,
            loanAmount = savedLoanAmount,
            updatedAt = at,
        )
    }

    override val icon: IconDraft
        get() = IconDraft(
            mark = mark,
            color = color,
        )

    override val problems: List<DraftProblem>
        get() {
            val nameProblems = if (trimmedName.isEmpty()) {
                listOf(
                    DraftProblem.emptyName,
                )
            } else {
                emptyList()
            }

            return nameProblems + icon.problems + kindProblems
        }

    fun locked(
        by: Wallet,
        hasRecords: Boolean,
        hasValuations: Boolean,
    ): WalletDraft = copy(
        recordedKind = if (hasRecords) by.kind else null,
        hasValuations = hasValuations,
    )

    fun newWallet(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): Wallet {
        validateProblems()

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
}
