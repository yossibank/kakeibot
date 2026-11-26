package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.icon.IconImage
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.colorOf
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.BalanceLine
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.afterLine
import com.yossibank.kakeibot.featuremodels.screens.entry.model.amount
import com.yossibank.kakeibot.featuremodels.screens.entry.model.currentLine
import com.yossibank.kakeibot.featuremodels.screens.entry.model.icon
import com.yossibank.kakeibot.featuremodels.screens.entry.model.idleAfterLine
import com.yossibank.kakeibot.featuremodels.screens.entry.model.isOverSourceBalance
import com.yossibank.kakeibot.featuremodels.screens.entry.model.loanRemaining
import com.yossibank.kakeibot.featuremodels.screens.entry.model.payOffLoan
import com.yossibank.kakeibot.featuremodels.screens.entry.model.recentTransfers
import com.yossibank.kakeibot.featuremodels.screens.entry.model.swapWallets
import com.yossibank.kakeibot.featuremodels.screens.entry.model.toWallet
import com.yossibank.kakeibot.featuremodels.screens.entry.model.wallet
import com.yossibank.kakeibot.featuremodels.screens.entry.model.walletTitle
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryText

@Composable
fun EntryTransferArea(
    model: EntryModel,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        EntryTransferPanel(model = model)

        EntryTransferRoutes(model = model)

        if (model.output.recentTransfers.isEmpty()) {
            Text(
                text = "チャージ・カードの支払い・口座のあいだの移動",
                color = Palette.subtext,
                style = textFont(size = FontSize.Caption),
            )
        }

        val remaining = model.output.loanRemaining

        if (remaining != null && remaining != model.output.amount.toLong()) {
            PayOffButton(
                remaining = remaining,
                onSelect = model::payOffLoan,
            )
        }
    }
}

@Composable
private fun EntryTransferPanel(model: EntryModel) {
    Column {
        WalletCard(
            model = model,
            isSource = true,
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(44.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            val link = Palette.accent.opacity(Emphasis.Medium)

            Canvas(
                modifier = Modifier
                    .padding(start = 16.dp)
                    .width(ICON_SIZE)
                    .fillMaxHeight(),
            ) {
                drawLine(
                    color = link,
                    start = Offset(size.width / 2, 0f),
                    end = Offset(size.width / 2, size.height),
                    strokeWidth = 2.dp.toPx(),
                    cap = StrokeCap.Round,
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(1.dp.toPx(), 4.dp.toPx())),
                )
            }

            Flow(
                amount = model.output.amount,
                modifier = Modifier.padding(start = 8.dp),
            )

            Spacer(modifier = Modifier.weight(1f))

            Box(
                modifier = Modifier
                    .padding(end = 20.dp)
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(Palette.card)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Medium),
                        shape = CircleShape,
                    ).clickable(onClick = model.state::swapWallets),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_swap),
                    contentDescription = null,
                    modifier = Modifier
                        .size(16.dp)
                        .rotate(90f),
                    tint = Palette.accent,
                )
            }
        }

        WalletCard(
            model = model,
            isSource = false,
        )
    }
}

@Composable
private fun Flow(
    amount: Int,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .height(24.dp)
            .clip(CircleShape)
            .background(Palette.accent.opacity(Emphasis.Subtle))
            .padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_arrow_downward),
            contentDescription = null,
            modifier = Modifier.size(12.dp),
            tint = Palette.accent,
        )

        if (amount > 0) {
            FittedText(
                text = AmountText.text(amount),
                color = Palette.accentStrong,
                style = textFont(size = FontSize.Caption),
            )
        }
    }
}

@Composable
private fun WalletCard(
    model: EntryModel,
    isSource: Boolean,
) {
    val wallet = if (isSource) model.output.wallet else model.output.toWallet
    val icon = wallet?.let { model.output.icon(of = it.iconId) }
    val corner = LocalThemeStyle.current.corner
    val shape = RoundedCornerShape(corner.radius(20.dp))
    val iconShape = RoundedCornerShape(corner.radius(12.dp))
    val tint = icon?.let { colorOf(hex = it.color) } ?: Palette.accent
    val isOver = isSource && model.output.isOverSourceBalance
    val current = wallet?.let(model.output::currentLine)
    val after = wallet?.let { model.output.afterLine(of = it, isSource = isSource) }
    val idleAfter = wallet?.let { model.output.idleAfterLine(of = it, isSource = isSource) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.card)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = shape,
            ).clickable {
                model.state.focus(
                    if (isSource) EntryModel.Field.Wallet else EntryModel.Field.ToWallet,
                )
            }.padding(
                start = 16.dp,
                end = 12.dp,
                top = 12.dp,
                bottom = 12.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(ICON_SIZE)
                .clip(iconShape)
                .background(tint.opacity(Emphasis.Subtle))
                .border(
                    width = 1.5.dp,
                    color = tint.opacity(Emphasis.Medium),
                    shape = iconShape,
                ),
            contentAlignment = Alignment.Center,
        ) {
            CompositionLocalProvider(LocalContentColor provides Palette.accent) {
                IconImage(
                    icon = icon,
                    size = 22.dp,
                )
            }
        }

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            RoleTag(
                title = if (isSource) model.output.walletTitle else EntryText.destinationTitle,
                isSource = isSource,
            )

            Text(
                text = wallet?.name ?: "選ぶ",
                color = if (wallet == null) Palette.hint else Palette.text,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                style = textFont(
                    size = FontSize.Small,
                    weight = FontWeight.Bold,
                ),
            )
        }

        Column(
            horizontalAlignment = Alignment.End,
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            val color = if (isOver) Palette.rose else Palette.subtext

            current?.let { BalanceText(line = it, color = color) }

            when {
                after != null -> BalanceText(line = after, color = color)
                idleAfter != null -> BalanceText(line = idleAfter, color = Palette.hint)
            }
        }

        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier.size(14.dp),
            tint = Palette.hint,
        )
    }
}

@Composable
private fun RoleTag(
    title: String,
    isSource: Boolean,
) {
    val modifier = if (isSource) {
        Modifier
            .clip(CircleShape)
            .background(Brush.linearGradient(listOf(Palette.accentStrong, Palette.accent)))
    } else {
        Modifier.border(
            width = 1.dp,
            color = Palette.accent.opacity(Emphasis.Medium),
            shape = CircleShape,
        )
    }

    Box(
        modifier = modifier
            .height(20.dp)
            .padding(horizontal = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            color = if (isSource) Palette.backgroundBottom else Palette.accent,
            style = textFont(
                size = FontSize.Micro,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun BalanceText(
    line: BalanceLine,
    color: Color,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        FittedText(
            text = line.title,
            color = color,
            style = textFont(size = FontSize.Caption),
        )

        FittedText(
            text = AmountText.text(line.amount.toInt()),
            color = color,
            style = displayFont(size = FontSize.Small),
        )
    }
}

private val ICON_SIZE = 44.dp
