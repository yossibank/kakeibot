package com.yossibank.kakeibot.features.screens.settings.recurrings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
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
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsDivider

@Composable
fun RecurringDetailRows(
    rows: List<RecurringDetailRow>,
    onOpen: (RecurringPanel) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .card(),
    ) {
        rows.forEachIndexed { index, row ->
            if (index > 0) {
                SettingsDivider()
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = Metrics.rowMinHeight)
                    .clickable { onOpen(row.panel) }
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    painter = painterResource(row.icon),
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Palette.accent,
                )

                Text(
                    text = row.panel.title,
                    modifier = Modifier.weight(1f),
                    color = Palette.text,
                    style = textFont(style = FontTextStyle.Subheadline),
                )

                FittedText(
                    text = row.value,
                    color = if (row.isEmpty) Palette.hint else Palette.accentStrong,
                    style = textFont(style = FontTextStyle.Subheadline),
                )

                Icon(
                    painter = painterResource(R.drawable.ic_chevron_right),
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = Palette.subtext,
                )
            }
        }
    }
}
