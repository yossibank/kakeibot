package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class AmountCalculatorTest {
    @RunWith(Parameterized::class)
    class CalculatesKeys(
        private val fixture: KeysCase,
    ) {
        @Serializable
        data class KeysCase(
            val summary: String,
            val keys: List<String>,
            val amount: Int,
            val expression: String,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun calculatesKeys() {
            var calculator = AmountCalculator()

            for (key in fixture.keys.map(::key)) {
                calculator = calculator.press(key)
            }

            assertEquals(fixture.amount, calculator.amount)
            assertEquals(fixture.expression, expression(calculator.tokens))
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<KeysCase> = CoreFixture.cases("entry/amount-calculator.json", KeysCase.serializer())
        }
    }

    class Pressing {
        @Test
        fun remembersTaxBaseUntilNextKey() {
            var calculator = AmountCalculator(amount = 1180)

            calculator = calculator.press(AmountCalculator.Key.Tax(AmountCalculator.TaxRate.standard))
            val note = calculator.taxNote
            calculator = calculator.press(AmountCalculator.Key.Digit(1))

            assertEquals(1180, note?.base)
            assertEquals(AmountCalculator.TaxRate.standard, note?.rate)
            assertNull(calculator.taxNote)
        }

        @Test
        fun startsFromExistingAmount() {
            var calculator = AmountCalculator(amount = 980)

            calculator = calculator.press(AmountCalculator.Key.Operation(AmountCalculator.Operation.add))
            calculator = calculator.press(AmountCalculator.Key.Digit(2))

            assertEquals(982, calculator.amount)
        }
    }
}

private fun key(text: String): AmountCalculator.Key {
    if (text.length == 1 && text[0] in '0'..'9') {
        return AmountCalculator.Key.Digit(text.toInt())
    }

    return when (text) {
        "00" -> AmountCalculator.Key.DoubleZero
        "000" -> AmountCalculator.Key.TripleZero
        "del" -> AmountCalculator.Key.Delete
        "ac" -> AmountCalculator.Key.Clear
        "+" -> AmountCalculator.Key.Operation(AmountCalculator.Operation.add)
        "-" -> AmountCalculator.Key.Operation(AmountCalculator.Operation.subtract)
        "*" -> AmountCalculator.Key.Operation(AmountCalculator.Operation.multiply)
        "/" -> AmountCalculator.Key.Operation(AmountCalculator.Operation.divide)
        "=" -> AmountCalculator.Key.Equals
        "tax8" -> AmountCalculator.Key.Tax(AmountCalculator.TaxRate.reduced)
        "tax10" -> AmountCalculator.Key.Tax(AmountCalculator.TaxRate.standard)
        else -> error("知らないキー: $text")
    }
}

private fun expression(tokens: List<AmountCalculator.Token>): String = tokens.joinToString(" ") { token ->
    when (token) {
        is AmountCalculator.Token.Number -> token.number.toString()

        is AmountCalculator.Token.Operation -> when (token.operation) {
            AmountCalculator.Operation.add -> "+"
            AmountCalculator.Operation.subtract -> "-"
            AmountCalculator.Operation.multiply -> "*"
            AmountCalculator.Operation.divide -> "/"
        }
    }
}
