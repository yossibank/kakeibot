package com.yossibank.kakeibot.designsystem.components.template

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont

enum class TemplateCardSize(
    internal val height: Dp,
    internal val padding: Dp,
    internal val spacing: Dp,
    internal val gap: Dp,
    internal val textSpacing: Dp,
    internal val badge: Dp,
    internal val amountHeight: Dp,
    internal val cornerRadius: Dp,
    internal val nameLines: Int,
) {
    Regular(
        height = 116.dp,
        padding = 12.dp,
        spacing = 8.dp,
        gap = 8.dp,
        textSpacing = 4.dp,
        badge = 32.dp,
        amountHeight = 26.dp,
        cornerRadius = 20.dp,
        nameLines = 2,
    ),
    Large(
        height = 172.dp,
        padding = 24.dp,
        spacing = 16.dp,
        gap = 12.dp,
        textSpacing = 8.dp,
        badge = 44.dp,
        amountHeight = 42.dp,
        cornerRadius = 24.dp,
        nameLines = 1,
    ),
    ;

    internal val nameSize: FontSize
        get() = if (this == Regular) FontSize.Body else FontSize.Headline

    internal val amountSize: FontSize
        get() = if (this == Regular) FontSize.Headline else FontSize.LargeTitle

    internal val emptyAmountSize: FontSize
        get() = if (this == Regular) FontSize.Small else FontSize.Body
}

@Composable
fun TemplateCard(
    icon: Icon?,
    detail: String,
    modifier: Modifier = Modifier,
    size: TemplateCardSize = TemplateCardSize.Regular,
    name: @Composable () -> Unit,
    amount: @Composable () -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .height(size.height)
            .card(cornerRadius = size.cornerRadius)
            .padding(horizontal = size.padding),
        verticalArrangement = Arrangement.spacedBy(size.spacing, Alignment.CenterVertically),
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(size.gap),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconTile(
                icon = icon,
                size = size.badge,
            )

            Column(verticalArrangement = Arrangement.spacedBy(size.textSpacing)) {
                name()

                FittedText(
                    text = detail,
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption).copy(letterSpacing = 1.sp),
                )
            }
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(0.5.dp)
                .background(Palette.accent.opacity(Emphasis.Soft)),
        )

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(size.amountHeight),
            contentAlignment = Alignment.CenterStart,
        ) {
            amount()
        }
    }
}

@Composable
fun TemplateCardName(
    name: String,
    size: TemplateCardSize,
) {
    Text(
        text = name,
        color = Palette.accentStrong,
        maxLines = size.nameLines,
        overflow = TextOverflow.Ellipsis,
        style = displayFont(
            size = size.nameSize,
            weight = FontWeight.Medium,
        ),
    )
}

@Composable
fun TemplateCardAmount(
    amount: Int?,
    size: TemplateCardSize,
) {
    if (amount != null) {
        AmountText(
            amount = amount,
            style = displayFont(
                size = size.amountSize,
                weight = FontWeight.Medium,
            ),
            color = Palette.accentStrong,
        )
    } else {
        Text(
            text = "毎回入れる",
            color = Palette.hint,
            style = displayFont(size = size.emptyAmountSize),
        )
    }
}
