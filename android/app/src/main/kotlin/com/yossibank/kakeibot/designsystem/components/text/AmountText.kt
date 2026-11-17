package com.yossibank.kakeibot.designsystem.components.text

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextOverflow
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.designsystem.theme.Palette
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

@Composable
fun AmountText(
    amount: Int,
    style: TextStyle,
    modifier: Modifier = Modifier,
    type: Entry.Kind? = null,
    sign: AmountText.Sign = AmountText.Sign.Auto,
    color: Color? = null,
    isCompact: Boolean = false,
) {
    val text = if (isCompact) {
        AmountText.compactText(
            amount = amount,
            type = type,
            sign = sign,
        )
    } else {
        AmountText.text(
            amount = amount,
            type = type,
            sign = sign,
        )
    }

    val typeColor = when (type) {
        Entry.Kind.income -> Palette.accent
        Entry.Kind.transfer -> Palette.subtext
        Entry.Kind.expense -> Palette.accentStrong
        null -> Palette.text
    }

    Text(
        text = text,
        modifier = modifier,
        color = color ?: typeColor,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        style = style.copy(fontFeatureSettings = "tnum"),
    )
}
