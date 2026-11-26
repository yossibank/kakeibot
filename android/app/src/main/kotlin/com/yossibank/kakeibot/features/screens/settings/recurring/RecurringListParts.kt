package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.title
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped

@Composable
internal fun TotalCard(
    type: Entry.Kind,
    total: Long,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "今月の${type.title}",
            color = Palette.accent,
            style = textFont(style = FontTextStyle.Caption2),
        )

        AmountText(
            amount = total.clamped,
            style = displayFont(size = FontSize.Headline),
            color = Palette.accentStrong,
        )
    }
}

@Composable
internal fun EmptyNote(text: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_repeat),
            contentDescription = null,
            modifier = Modifier.size(28.dp),
            tint = Palette.accent,
        )

        Text(
            text = text,
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Subheadline),
        )
    }
}
