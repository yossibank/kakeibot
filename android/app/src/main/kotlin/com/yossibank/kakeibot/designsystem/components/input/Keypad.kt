package com.yossibank.kakeibot.designsystem.components.input

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.shared.amount.symbol

@Composable
fun Keypad(
    calculator: AmountCalculator,
    onKey: (AmountCalculator.Key) -> Unit,
    modifier: Modifier = Modifier,
    keyHeight: Dp = 50.dp,
) {
    val active = calculator.taxNote?.let { AmountCalculator.Key.Tax(it.rate) }

    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        rows.forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { key ->
                    KeyButton(
                        key = key,
                        isActive = key == active,
                        height = keyHeight,
                        onKey = onKey,
                        modifier = Modifier.weight(1f),
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun KeyButton(
    key: AmountCalculator.Key,
    isActive: Boolean,
    height: Dp,
    onKey: (AmountCalculator.Key) -> Unit,
    modifier: Modifier = Modifier,
) {
    val feedback = LocalHapticFeedback.current
    val hasHaptics = LocalThemeStyle.current.haptics
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(16.dp))
    val tint = Palette.accent.opacity(Emphasis.Subtle)
    val rim = Palette.accent.opacity(Emphasis.Muted)

    val background = when (key) {
        is AmountCalculator.Key.Tax -> if (isActive) tint else Color.Transparent
        is AmountCalculator.Key.Operation -> tint
        AmountCalculator.Key.Equals -> Palette.accent
        else -> Color.Transparent
    }

    val stroke = when (key) {
        AmountCalculator.Key.Delete -> rim
        is AmountCalculator.Key.Tax -> if (isActive) Palette.accent else rim
        else -> Color.Transparent
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clip(shape)
            .background(background)
            .border(
                width = 0.75.dp,
                color = stroke,
                shape = shape,
            ).combinedClickable(
                onLongClick = if (key == AmountCalculator.Key.Delete) {
                    {
                        if (hasHaptics) {
                            feedback.performHapticFeedback(HapticFeedbackType.LongPress)
                        }

                        onKey(AmountCalculator.Key.Clear)
                    }
                } else {
                    null
                },
                onClick = { onKey(key) },
            ),
        contentAlignment = Alignment.Center,
    ) {
        KeyLabel(
            key = key,
            isActive = isActive,
        )
    }
}

@Composable
private fun KeyLabel(
    key: AmountCalculator.Key,
    isActive: Boolean,
) {
    when (key) {
        is AmountCalculator.Key.Digit -> DigitText(key.digit.toString())

        AmountCalculator.Key.DoubleZero -> DigitText("00")

        AmountCalculator.Key.TripleZero -> DigitText("000")

        AmountCalculator.Key.Delete,
        AmountCalculator.Key.Clear,
        -> Icon(
            painter = painterResource(R.drawable.ic_backspace),
            contentDescription = null,
            modifier = Modifier.size(24.dp),
            tint = Palette.text,
        )

        is AmountCalculator.Key.Tax -> TaxLabel(
            key = key,
            isActive = isActive,
        )

        is AmountCalculator.Key.Operation -> Text(
            text = key.operation.symbol,
            color = Palette.accentStrong,
            style = textFont(size = FontSize.Headline),
        )

        AmountCalculator.Key.Equals -> Text(
            text = "＝",
            color = Palette.backgroundBottom,
            style = textFont(
                size = FontSize.Headline,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun TaxLabel(
    key: AmountCalculator.Key.Tax,
    isActive: Boolean,
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = "税込",
            color = if (isActive) Palette.accent else Palette.subtext,
            style = textFont(size = FontSize.Micro),
        )

        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = key.rate.rawValue.toString(),
                modifier = Modifier.alignByBaseline(),
                color = if (isActive) Palette.accentStrong else Palette.text,
                style = displayFont(size = FontSize.Headline),
            )

            Text(
                text = "%",
                modifier = Modifier.alignByBaseline(),
                color = if (isActive) Palette.accentStrong else Palette.text,
                style = displayFont(size = FontSize.Caption),
            )
        }
    }
}

@Composable
private fun DigitText(text: String) {
    Text(
        text = text,
        color = Palette.text,
        style = displayFont(size = FontSize.Title),
    )
}

private val rows: List<List<AmountCalculator.Key>> = listOf(
    listOf(
        AmountCalculator.Key.Delete,
        AmountCalculator.Key.Tax(AmountCalculator.TaxRate.reduced),
        AmountCalculator.Key.Tax(AmountCalculator.TaxRate.standard),
        AmountCalculator.Key.Operation(AmountCalculator.Operation.divide),
    ),
    listOf(
        AmountCalculator.Key.Digit(1),
        AmountCalculator.Key.Digit(2),
        AmountCalculator.Key.Digit(3),
        AmountCalculator.Key.Operation(AmountCalculator.Operation.multiply),
    ),
    listOf(
        AmountCalculator.Key.Digit(4),
        AmountCalculator.Key.Digit(5),
        AmountCalculator.Key.Digit(6),
        AmountCalculator.Key.Operation(AmountCalculator.Operation.subtract),
    ),
    listOf(
        AmountCalculator.Key.Digit(7),
        AmountCalculator.Key.Digit(8),
        AmountCalculator.Key.Digit(9),
        AmountCalculator.Key.Operation(AmountCalculator.Operation.add),
    ),
    listOf(
        AmountCalculator.Key.DoubleZero,
        AmountCalculator.Key.Digit(0),
        AmountCalculator.Key.TripleZero,
        AmountCalculator.Key.Equals,
    ),
)
