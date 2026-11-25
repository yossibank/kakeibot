package com.yossibank.kakeibot.features.screens.tabs.review.view

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.model.ReviewModel
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped

@Composable
fun ReviewBalanceBars(
    bars: List<ReviewModel.BalanceBar>,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        bars.forEach { bar ->
            BalanceBar(bar = bar)
        }
    }
}

@Composable
private fun BalanceBar(bar: ReviewModel.BalanceBar) {
    val tint = if (bar.type == Entry.Kind.income) Palette.accent else Palette.accentStrong

    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = bar.title,
                modifier = Modifier.weight(1f),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )

            AmountText(
                amount = bar.amount.clamped,
                style = displayFont(size = FontSize.Body),
                type = bar.type,
            )
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(CircleShape)
                .background(tint.opacity(Emphasis.Faint)),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(bar.ratio.toFloat())
                    .fillMaxHeight()
                    .clip(CircleShape)
                    .background(tint),
            )
        }
    }
}
