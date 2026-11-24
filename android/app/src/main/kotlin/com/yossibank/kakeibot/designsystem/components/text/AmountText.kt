package com.yossibank.kakeibot.designsystem.components.text

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextOverflow
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.TextScale
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText

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

    FittedText(
        text = text,
        style = style.copy(fontFeatureSettings = "tnum"),
        modifier = modifier,
        color = color ?: typeColor,
        floor = TextScale.AMOUNT_FLOOR,
    )
}
