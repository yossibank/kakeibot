package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.symbol
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryText

val EntryModel.Output.walletTitle: String
    get() = EntryText.walletTitle(state.form.type)

val EntryModel.Output.dateValue: String
    get() = EntryText.dateValue(
        date = state.form.date,
        today = input.today,
    )

val EntryModel.Output.canSave: Boolean
    get() = draft?.problems?.isEmpty() == true

val EntryModel.Output.opensKeypadOnSave: Boolean
    get() = state.focus.field != EntryModel.Field.Amount && isBlank

val EntryModel.Output.saveTitle: String
    get() {
        if (isEditing) {
            return saveAction
        }

        if (amount <= 0) {
            return "金額を入れてください"
        }

        if (state.form.type == Entry.Kind.transfer && state.form.toWalletId == null) {
            return "${EntryText.destinationTitle}を選んでください"
        }

        return saveAction
    }

val EntryModel.Output.expressionText: String?
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

val EntryModel.Output.routeText: String
    get() {
        val source = wallet?.name
        val destination = toWallet?.name

        if (source == null || destination == null) {
            return "口座を選ぶ"
        }

        return "$source → $destination"
    }

val EntryModel.Output.categoryText: String
    get() {
        val name = category?.name ?: return "選ぶ"
        val tag = tags.firstOrNull { it.id == state.form.tagId }?.name ?: return name
        return "$name・$tag"
    }

private val EntryModel.Output.saveAction: String
    get() = when {
        isEditing -> "変更を保存"
        state.form.type == Entry.Kind.transfer -> "振り替える"
        else -> "記録する"
    }
