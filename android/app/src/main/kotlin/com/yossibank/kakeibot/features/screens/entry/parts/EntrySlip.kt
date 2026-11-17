package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel

@Composable
fun EntrySlip(
    model: EntryModel,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.card()) {
        SlipRow(
            title = "カテゴリ",
            value = model.category?.name ?: "選ぶ",
            isActive = model.field == EntryModel.Field.Category,
            onSelect = { model.focus(EntryModel.Field.Category) },
        ) {
            IconTile(
                icon = model.category?.let { model.icon(of = it.iconId) },
                size = 30.dp,
            )
        }

        Divider()

        SlipRow(
            title = model.walletTitle,
            value = model.wallet?.name ?: "選ぶ",
            isActive = model.field == EntryModel.Field.Wallet,
            onSelect = { model.focus(EntryModel.Field.Wallet) },
        ) {
            IconTile(
                icon = model.wallet?.let { model.icon(of = it.iconId) },
                size = 30.dp,
            )
        }

        Divider()

        SlipRow(
            title = "日付",
            value = model.dateText,
            isActive = model.field == EntryModel.Field.Date,
            onSelect = { model.focus(EntryModel.Field.Date) },
        ) {
            DayTile(day = model.date.day)
        }

        Divider()

        AmountRow(model = model)

        Divider()

        MemoRow(model = model)
    }
}

@Composable
private fun SlipRow(
    title: String,
    value: String,
    isActive: Boolean,
    onSelect: () -> Unit,
    icon: @Composable () -> Unit,
) {
    ActiveRow(
        isActive = isActive,
        modifier = Modifier
            .height(52.dp)
            .clickable(onClick = onSelect),
    ) {
        icon()

        Text(
            text = title,
            color = if (isActive) Palette.accent else Palette.subtext,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )

        Spacer(modifier = Modifier.weight(1f))

        Text(
            text = value,
            color = Palette.text,
            maxLines = 1,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.Medium,
            ),
        )

        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = if (isActive) Palette.accent else Palette.subtext,
        )
    }
}

@Composable
private fun AmountRow(model: EntryModel) {
    val isActive = model.field == EntryModel.Field.Amount

    ActiveRow(
        isActive = isActive,
        modifier = Modifier
            .height(80.dp)
            .clickable { model.focus(EntryModel.Field.Amount) },
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .background(
                    color = Palette.accent,
                    shape = CircleShape,
                ),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "¥",
                color = Palette.backgroundTop,
                style = textFont(
                    size = FontSize.Body,
                    weight = FontWeight.Bold,
                ),
            )
        }

        Text(
            text = "金額",
            color = if (isActive) Palette.accent else Palette.subtext,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )

        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.End,
        ) {
            model.expressionText?.let { expression ->
                Text(
                    text = expression,
                    color = Palette.subtext,
                    maxLines = 1,
                    style = textFont(size = FontSize.Caption),
                )
            }

            AmountText(
                amount = model.amount,
                style = displayFont(
                    size = FontSize.Display,
                    weight = FontWeight.Bold,
                ),
                color = if (model.amount > 0) Palette.accentStrong else Palette.hint,
            )
        }
    }
}

@Composable
private fun MemoRow(model: EntryModel) {
    val style = textFont(size = FontSize.Body)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_edit),
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = Palette.subtext,
        )

        BasicTextField(
            value = model.memo,
            onValueChange = { model.memo = it },
            modifier = Modifier.weight(1f),
            textStyle = style.copy(color = Palette.text),
            singleLine = true,
            cursorBrush = SolidColor(Palette.accent),
            decorationBox = { field ->
                if (model.memo.isEmpty()) {
                    Text(
                        text = "店名や買ったものをメモ",
                        color = Palette.hint,
                        style = style,
                    )
                }

                field()
            },
        )
    }
}

@Composable
private fun ActiveRow(
    isActive: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit,
) {
    val fill = if (isActive) Palette.accent.opacity(Emphasis.Subtle) else Color.Transparent

    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(fill),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .width(3.dp)
                .fillMaxHeight()
                .background(if (isActive) Palette.accent else Color.Transparent),
        )

        Row(
            modifier = Modifier
                .weight(1f)
                .padding(
                    start = 13.dp,
                    end = 12.dp,
                ),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            content()
        }
    }
}

@Composable
private fun DayTile(day: Int) {
    val shape = RoundedCornerShape(8.dp)

    Box(
        modifier = Modifier
            .size(30.dp)
            .background(
                color = Palette.accent.opacity(Emphasis.Subtle),
                shape = shape,
            ).border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = shape,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = day.toString(),
            color = Palette.accentStrong,
            style = displayFont(
                size = FontSize.Small,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun Divider() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(Palette.line),
    )
}
