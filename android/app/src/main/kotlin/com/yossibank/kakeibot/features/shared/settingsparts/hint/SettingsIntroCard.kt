package com.yossibank.kakeibot.features.shared.settingsparts.hint

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldInput
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldModel
import com.yossibank.kakeibot.features.shared.settingsparts.input.RoundIconButton
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsDivider

data class SettingsIntroNote(
    val icon: Int,
    val text: String,
    val rotation: Float = 0f,
) {
    companion object {
        val arrange = SettingsIntroNote(
            icon = R.drawable.ic_swap,
            text = "長押しで並べ替え・止めて非表示にできます",
            rotation = 90f,
        )

        val swipeDelete = SettingsIntroNote(
            icon = R.drawable.ic_chevron_right,
            text = "横に払うと、非表示と削除を選べます",
            rotation = 180f,
        )
    }
}

@Composable
fun SettingsIntroCard(
    icon: Int,
    headline: Pair<String, String>,
    fold: SettingsFoldInput,
    model: SettingsFoldModel,
    notes: List<SettingsIntroNote> = emptyList(),
) {
    LaunchedEffect(fold) {
        model.loadFold(fold)
    }

    AnimatedVisibility(
        visible = fold.isClosed == false,
        enter = fadeIn() + expandVertically(),
        exit = fadeOut() + shrinkVertically(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .card()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            IntroHeader(
                icon = icon,
                headline = headline,
                fold = fold,
                model = model,
            )

            if (notes.isNotEmpty()) {
                SettingsDivider()

                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    notes.forEach { note ->
                        NoteRow(note = note)
                    }
                }
            }
        }
    }
}

@Composable
fun SettingsHintButton(
    fold: SettingsFoldInput,
    model: SettingsFoldModel,
) {
    AnimatedVisibility(
        visible = fold.isClosed == true,
        enter = fadeIn(),
        exit = fadeOut(),
    ) {
        RoundIconButton(
            icon = R.drawable.ic_help,
            onSelect = {
                model.perform {
                    it.setFold(
                        fold = fold,
                        isClosed = false,
                    )
                }
            },
        )
    }
}

@Composable
private fun IntroHeader(
    icon: Int,
    headline: Pair<String, String>,
    fold: SettingsFoldInput,
    model: SettingsFoldModel,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .border(
                    width = 1.dp,
                    color = Palette.accent.opacity(Emphasis.Muted),
                    shape = CircleShape,
                ),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                painter = painterResource(icon),
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = Palette.accent,
            )
        }

        Column(modifier = Modifier.weight(1f)) {
            listOf(headline.first, headline.second).forEach { line ->
                FittedText(
                    text = line,
                    color = Palette.accentStrong,
                    style = displayFont(
                        size = FontSize.Body,
                        weight = FontWeight.Medium,
                    ),
                )
            }
        }

        RoundIconButton(
            icon = R.drawable.ic_close,
            onSelect = {
                model.perform {
                    it.setFold(
                        fold = fold,
                        isClosed = true,
                    )
                }
            },
        )
    }
}

@Composable
private fun NoteRow(note: SettingsIntroNote) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(note.icon),
            contentDescription = null,
            modifier = Modifier
                .size(18.dp)
                .rotate(note.rotation),
            tint = Palette.accent,
        )

        FittedText(
            text = note.text,
            color = Palette.text,
            style = textFont(style = FontTextStyle.Footnote),
        )
    }
}
