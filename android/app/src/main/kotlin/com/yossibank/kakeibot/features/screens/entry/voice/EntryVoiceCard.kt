package com.yossibank.kakeibot.features.screens.entry.voice

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.categories
import com.yossibank.kakeibot.featuremodels.screens.entry.model.wallet
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceFlow
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryText

@Composable
fun EntryVoiceCard(
    flow: EntryVoiceFlow,
    model: EntryModel,
    today: LocalDate,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(16.dp))

    Column(
        modifier = modifier
            .fillMaxSize()
            .clip(shape)
            .background(Palette.paper)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Soft),
                shape = shape,
            ).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        when (val phase = flow.state.phase) {
            EntryVoiceFlow.Phase.Denied -> {
                Denied(
                    onCancel = flow::cancel,
                    onOpenSettings = onOpenSettings,
                )
            }

            is EntryVoiceFlow.Phase.Reading -> {
                Reading(text = phase.transcript)
            }

            is EntryVoiceFlow.Phase.Listening -> {
                Listening(
                    flow = flow,
                    listening = phase,
                    model = model,
                    today = today,
                )
            }

            EntryVoiceFlow.Phase.Idle -> {}
        }
    }
}

@Composable
private fun ColumnScope.Listening(
    flow: EntryVoiceFlow,
    listening: EntryVoiceFlow.Phase.Listening,
    model: EntryModel,
    today: LocalDate,
) {
    EntryVoiceWave(
        levels = listening.levels,
        reach = 15,
        height = 40.dp,
        modifier = Modifier.fillMaxWidth(),
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(72.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = listening.transcript.ifEmpty { "話してください\n$EXAMPLE" },
            color = if (listening.transcript.isEmpty()) Palette.hint else Palette.text,
            textAlign = TextAlign.Center,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis,
            style = textFont(
                size = if (listening.transcript.isEmpty()) FontSize.Small else FontSize.Body,
                weight = FontWeight.Medium,
            ),
        )
    }

    val reading = listening.preview

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Chip(
            label = "金額",
            value = reading?.amount?.let { AmountText.text(it) },
        )

        Chip(
            label = "カテゴリ",
            value = reading?.categoryId?.let { id ->
                model.output.categories.firstOrNull { it.id == id }?.name
            },
        )
    }

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Chip(
            label = "日付",
            value = reading?.date?.let { date ->
                EntryText.shortDateText(
                    date = date,
                    today = today,
                )
            },
        )

        Chip(
            label = "口座",
            value = reading?.walletId?.let { model.output.wallet(of = it)?.name },
        )

        Chip(
            label = "メモ",
            value = reading?.memo,
        )
    }

    Spacer(modifier = Modifier.weight(1f))

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        CardButton(
            title = "やめる",
            isFilled = false,
            onSelect = flow::cancel,
        )

        FinishButton(
            silenceStart = listening.silenceStart,
            duration = flow.input.silenceMillis,
            passed = flow::silencePassed,
            onSelect = flow::finish,
        )
    }
}

@Composable
private fun Reading(text: String) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "読んでいます",
            color = Palette.accent,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )

        if (text.isNotEmpty()) {
            Text(
                text = text,
                color = Palette.text,
                textAlign = TextAlign.Center,
                style = textFont(size = FontSize.Body),
            )
        }
    }
}

@Composable
private fun ColumnScope.Denied(
    onCancel: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .weight(1f),
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_mic),
            contentDescription = null,
            modifier = Modifier.size(32.dp),
            tint = Palette.rose,
        )

        Text(
            text = "マイクが使えません",
            color = Palette.text,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )

        Text(
            text = "声で記録するには、端末の設定で\nかけいぼっとの「マイク」を許可してください",
            color = Palette.subtext,
            textAlign = TextAlign.Center,
            style = textFont(size = FontSize.Small),
        )
    }

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        CardButton(
            title = "やめる",
            isFilled = false,
            onSelect = onCancel,
        )

        CardButton(
            title = "設定を開く",
            isFilled = true,
            onSelect = onOpenSettings,
        )
    }
}

@Composable
private fun RowScope.Chip(
    label: String,
    value: String?,
) {
    val fill = if (value != null) Palette.accent.opacity(Emphasis.Subtle) else Color.Transparent

    Box(
        modifier = Modifier
            .weight(1f)
            .height(32.dp)
            .clip(CircleShape)
            .background(fill)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(
                    if (value !=
                        null
                    ) {
                        Emphasis.Medium
                    } else {
                        Emphasis.Soft
                    },
                ),
                shape = CircleShape,
            ).padding(horizontal = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        FittedText(
            text = value ?: label,
            color = if (value != null) Palette.accentStrong else Palette.hint,
            style = textFont(
                size = FontSize.Caption,
                weight = if (value != null) FontWeight.SemiBold else FontWeight.Normal,
            ),
        )
    }
}

@Composable
private fun RowScope.CardButton(
    title: String,
    isFilled: Boolean,
    onSelect: () -> Unit,
) {
    Box(
        modifier = Modifier
            .weight(1f)
            .height(44.dp)
            .clip(CircleShape)
            .background(if (isFilled) Palette.accent else Color.Transparent)
            .border(
                width = 1.dp,
                color = if (isFilled) Palette.accent else Palette.subtext.opacity(Emphasis.Medium),
                shape = CircleShape,
            ).clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            color = if (isFilled) Palette.backgroundTop else Palette.subtext,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun RowScope.FinishButton(
    silenceStart: Long?,
    duration: Long,
    passed: (Long) -> Long,
    onSelect: () -> Unit,
) {
    val fill = remember { Animatable(0f) }
    val strongFill = Palette.accentStrong.opacity(Emphasis.Medium)

    LaunchedEffect(silenceStart) {
        if (silenceStart == null) {
            fill.snapTo(0f)
            return@LaunchedEffect
        }

        val start = passed(silenceStart)

        fill.snapTo(start.toFloat() / duration)
        fill.animateTo(
            targetValue = 1f,
            animationSpec = tween(
                durationMillis = (duration - start).toInt(),
                easing = LinearEasing,
            ),
        )
    }

    Box(
        modifier = Modifier
            .weight(1f)
            .height(44.dp)
            .clip(CircleShape)
            .background(Palette.accent)
            .drawBehind {
                drawRect(
                    color = strongFill,
                    size = size.copy(width = size.width * fill.value),
                )
            }.clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "話し終えた",
            color = Palette.backgroundTop,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.Bold,
            ),
        )
    }
}

private const val EXAMPLE = "例：昨日 ランチ 980円 カードで"
