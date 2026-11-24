package com.yossibank.kakeibot.featuremodels.shared.amount

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator

val AmountCalculator.Operation.symbol: String
    get() = when (this) {
        AmountCalculator.Operation.add -> "＋"
        AmountCalculator.Operation.subtract -> "−"
        AmountCalculator.Operation.multiply -> "×"
        AmountCalculator.Operation.divide -> "÷"
    }
