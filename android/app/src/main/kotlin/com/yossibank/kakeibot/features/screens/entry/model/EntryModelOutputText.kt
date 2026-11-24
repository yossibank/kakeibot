package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.designsystem.components.input.symbol
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.features.shared.entrylist.EntryText

val EntryModel.Output.walletTitle: String
    get() = EntryText.walletTitle(state.form.type)

val EntryModel.Output.dateText: String
    get() = EntryText.relativeDate(
        date = state.form.date,
        today = state.today,
    )

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
