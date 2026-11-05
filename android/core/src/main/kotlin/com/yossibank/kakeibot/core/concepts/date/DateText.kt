package com.yossibank.kakeibot.core.concepts.date

import kotlin.math.absoluteValue

internal object DateText {
    val yearRange = 1..9999

    fun numbers(
        text: String,
        digits: List<Int>,
    ): List<Int>? {
        val parts = text.split("-")

        if (parts.size != digits.size) {
            return null
        }

        val numbers = parts.zip(digits).mapNotNull { (part, count) ->
            number(
                part = part,
                digits = count,
            )
        }

        return if (numbers.size == digits.size) numbers else null
    }

    fun padded(
        value: Int,
        digits: Int,
    ): String {
        val text = value.toLong().absoluteValue.toString()
        val sign = if (value < 0) "-" else ""

        return sign + text.padStart(digits, '0')
    }

    private fun number(
        part: String,
        digits: Int,
    ): Int? {
        if (part.length != digits || !part.all { it in '0'..'9' }) {
            return null
        }

        return part.toInt()
    }
}
