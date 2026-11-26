package com.yossibank.kakeibot.features.screens.tabs.review.view

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.model.ReviewModel

@Composable
fun ReviewComparison(
    model: ReviewModel,
    modifier: Modifier = Modifier,
) {
    val change = model.output.change

    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (model.output.hasPreviousEntries) {
            Icon(
                painter = painterResource(changeIcon(change)),
                contentDescription = null,
                modifier = Modifier.size(14.dp),
                tint = changeColor(
                    change = change,
                    kind = model.input.kind,
                ),
            )
        }

        Text(
            text = model.output.comparisonText,
            color = Palette.text,
            style = textFont(style = FontTextStyle.Footnote),
        )
    }
}

private fun changeIcon(change: Long): Int = when {
    change > 0 -> R.drawable.ic_arrow_up_right
    change < 0 -> R.drawable.ic_arrow_down_right
    else -> R.drawable.ic_equal
}

@Composable
private fun changeColor(
    change: Long,
    kind: ReviewKind,
): Color {
    if (change == 0L) {
        return Palette.subtext
    }

    val isGood = if (kind == ReviewKind.expense) change < 0 else change > 0

    return if (isGood) Palette.accent else Palette.rose
}
