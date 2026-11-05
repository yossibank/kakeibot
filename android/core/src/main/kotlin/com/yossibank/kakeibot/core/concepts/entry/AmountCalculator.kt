package com.yossibank.kakeibot.core.concepts.entry

import java.math.BigInteger

@ConsistentCopyVisibility
data class AmountCalculator private constructor(
    val tokens: List<Token>,
    val taxNote: TaxNote?,
    private val isShowingResult: Boolean,
) {
    constructor(amount: Int = 0) : this(
        tokens = if (amount > 0) listOf(Token.Number(amount)) else emptyList(),
        taxNote = null,
        isShowingResult = amount > 0,
    )

    sealed interface Key {
        data class Digit(
            val digit: Int,
        ) : Key

        data object DoubleZero : Key

        data object TripleZero : Key

        data object Delete : Key

        data object Clear : Key

        data class Operation(
            val operation: AmountCalculator.Operation,
        ) : Key

        data object Equals : Key

        data class Tax(
            val rate: TaxRate,
        ) : Key
    }

    enum class Operation {
        add,
        subtract,
        multiply,
        divide,
        ;

        internal fun apply(
            lhs: BigInteger,
            rhs: BigInteger,
        ): BigInteger = when (this) {
            add -> lhs + rhs
            subtract -> lhs - rhs
            multiply -> (lhs * rhs).coerceIn(-ceiling, ceiling)
            divide -> if (rhs.signum() == 0) lhs else lhs / rhs
        }

        private companion object {
            val ceiling: BigInteger = BigInteger.ONE.shiftLeft(126) - BigInteger.ONE
        }
    }

    enum class TaxRate(
        val rawValue: Int,
    ) {
        reduced(8),
        standard(10),
        ;

        companion object {
            fun of(rawValue: Int): TaxRate? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }

    sealed interface Token {
        data class Number(
            val number: Int,
        ) : Token

        data class Operation(
            val operation: AmountCalculator.Operation,
        ) : Token
    }

    data class TaxNote(
        val base: Int,
        val rate: TaxRate,
    )

    val value: Int
        get() {
            var total = BigInteger.ZERO
            var pending = Operation.add

            for (token in tokens) {
                when (token) {
                    is Token.Number -> total = pending.apply(
                        lhs = total,
                        rhs = token.number.toBigInteger(),
                    )

                    is Token.Operation -> pending = token.operation
                }
            }

            val limit = maxValue.toBigInteger()

            return total.coerceIn(-limit, limit).toInt()
        }

    val amount: Int
        get() = value.coerceIn(0, maxValue)

    val hasOperation: Boolean
        get() = tokens.any { it is Token.Operation }

    fun press(key: Key): AmountCalculator {
        val calculator = copy(taxNote = null)

        return when (key) {
            is Key.Digit -> calculator.append(
                digit = key.digit,
                shift = 10,
            )

            Key.DoubleZero -> calculator.append(
                digit = 0,
                shift = 100,
            )

            Key.TripleZero -> calculator.append(
                digit = 0,
                shift = 1000,
            )

            Key.Delete -> calculator.deleteLast()

            Key.Clear -> calculator.clear()

            is Key.Operation -> calculator.append(key.operation)

            Key.Equals -> calculator.settle()

            is Key.Tax -> calculator.applyTax(key.rate)
        }
    }

    private fun append(
        digit: Int,
        shift: Int,
    ): AmountCalculator {
        val base = if (isShowingResult) clear() else this
        val last = base.tokens.lastOrNull()

        if (last !is Token.Number) {
            return if (shift == 10) base.copy(tokens = base.tokens + Token.Number(digit)) else base
        }

        val next = last.number.toLong() * shift + digit

        if (next > maxValue) {
            return base
        }

        return base.copy(tokens = base.tokens.dropLast(1) + Token.Number(next.toInt()))
    }

    private fun deleteLast(): AmountCalculator {
        val last = tokens.lastOrNull() ?: return copy(isShowingResult = false)
        val remaining = tokens.dropLast(1)

        val shortened = if (last is Token.Number && last.number >= 10) {
            remaining + Token.Number(last.number / 10)
        } else {
            remaining
        }

        return copy(
            tokens = shortened,
            isShowingResult = false,
        )
    }

    private fun clear(): AmountCalculator = copy(
        tokens = emptyList(),
        isShowingResult = false,
    )

    private fun append(operation: Operation): AmountCalculator {
        val tokens = when (tokens.lastOrNull()) {
            null -> tokens
            is Token.Operation -> tokens.dropLast(1) + Token.Operation(operation)
            is Token.Number -> tokens + Token.Operation(operation)
        }

        return copy(
            tokens = tokens,
            isShowingResult = false,
        )
    }

    private fun settle(): AmountCalculator {
        val trimmed = if (tokens.lastOrNull() is Token.Operation) copy(tokens = tokens.dropLast(1)) else this
        val amount = trimmed.amount

        return trimmed.copy(
            tokens = if (amount > 0) listOf(Token.Number(amount)) else emptyList(),
            isShowingResult = true,
        )
    }

    private fun applyTax(rate: TaxRate): AmountCalculator {
        val settled = settle()
        val last = settled.tokens.lastOrNull() as? Token.Number ?: return settled
        val base = last.number
        val withTax = base.toLong() * (100 + rate.rawValue) / 100
        val taxed = minOf(withTax, maxValue.toLong()).toInt()

        return settled.copy(
            tokens = listOf(Token.Number(taxed)),
            taxNote = TaxNote(
                base = base,
                rate = rate,
            ),
        )
    }

    companion object {
        const val maxValue = 999_999_999
    }
}
