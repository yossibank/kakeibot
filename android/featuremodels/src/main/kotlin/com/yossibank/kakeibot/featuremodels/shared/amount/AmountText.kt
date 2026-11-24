package com.yossibank.kakeibot.featuremodels.shared.amount

import com.yossibank.kakeibot.core.concepts.entry.Entry
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.abs

object AmountText {
    enum class Sign {
        Auto,
        Plus,
    }

    private const val COMPACT_FLOOR = 1_000_000

    private val locale = Locale.JAPAN

    fun number(value: Int): String = NumberFormat.getIntegerInstance(locale).format(value)

    fun text(
        amount: Int,
        type: Entry.Kind? = null,
        sign: Sign = Sign.Auto,
    ): String {
        val mark = mark(
            amount = amount,
            type = type,
            sign = sign,
        )

        return "$mark¥${number(abs(amount))}"
    }

    fun compactText(
        amount: Int,
        type: Entry.Kind? = null,
        sign: Sign = Sign.Auto,
    ): String {
        if (abs(amount) < COMPACT_FLOOR) {
            return text(
                amount = amount,
                type = type,
                sign = sign,
            )
        }

        val mark = mark(
            amount = amount,
            type = type,
            sign = sign,
        )

        return "$mark${number(abs(amount) / 10000)}万円"
    }

    private fun mark(
        amount: Int,
        type: Entry.Kind?,
        sign: Sign,
    ): String = when {
        amount < 0 -> "−"
        type == Entry.Kind.income || (sign == Sign.Plus && amount > 0) -> "+"
        else -> ""
    }
}

val Long.clamped: Int
    get() = coerceIn(Int.MIN_VALUE.toLong(), Int.MAX_VALUE.toLong()).toInt()
