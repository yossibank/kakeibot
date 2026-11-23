package com.yossibank.kakeibot.features.shared.settingsparts.layout

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.features.shared.settingsparts.input.RoundIconButton

@Composable
fun SettingsHeader(
    title: String,
    isRoot: Boolean,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    trailing: @Composable () -> Unit = {},
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(44.dp),
    ) {
        RoundIconButton(
            icon = if (isRoot) R.drawable.ic_close else R.drawable.ic_chevron_right,
            rotation = if (isRoot) 0f else 180f,
            onSelect = onBack,
            modifier = Modifier.align(Alignment.CenterStart),
        )

        FittedText(
            text = title,
            modifier = Modifier
                .align(Alignment.Center)
                .padding(horizontal = 56.dp),
            color = Palette.accentStrong,
            textAlign = TextAlign.Center,
            style = displayFont(size = FontSize.Headline),
        )

        Box(modifier = Modifier.align(Alignment.CenterEnd)) {
            trailing()
        }
    }
}
