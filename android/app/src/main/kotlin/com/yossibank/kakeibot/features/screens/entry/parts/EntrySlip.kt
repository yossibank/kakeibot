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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.categories
import com.yossibank.kakeibot.featuremodels.screens.entry.model.category
import com.yossibank.kakeibot.featuremodels.screens.entry.model.categoryText
import com.yossibank.kakeibot.featuremodels.screens.entry.model.dateValue
import com.yossibank.kakeibot.featuremodels.screens.entry.model.expressionText
import com.yossibank.kakeibot.featuremodels.screens.entry.model.icon
import com.yossibank.kakeibot.featuremodels.screens.entry.model.isDateFromVoice
import com.yossibank.kakeibot.featuremodels.screens.entry.model.isWalletFromVoice
import com.yossibank.kakeibot.featuremodels.screens.entry.model.routeText
import com.yossibank.kakeibot.featuremodels.screens.entry.model.wallet
import com.yossibank.kakeibot.featuremodels.screens.entry.model.walletTitle
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceFlow
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceWave

@Composable
fun EntrySlip(
    model: EntryModel,
    onOpenItems: () -> Unit,
    onVoice: (() -> Unit)?,
    listening: EntryVoiceFlow.Phase.Listening?,
    modifier: Modifier = Modifier,
) {
    val preview = listening?.preview

    Column(modifier = modifier.card()) {
        if (model.state.form.type != Entry.Kind.transfer) {
            SlipRow(
                title = "カテゴリ",
                value = preview?.categoryId
                    ?.let { id -> model.output.categories.firstOrNull { it.id == id }?.name }
                    ?: model.output.categoryText,
                isActive = model.state.field == EntryModel.Field.Category,
                onSelect = { model.state.focus(EntryModel.Field.Category) },
            ) {
                IconTile(
                    icon = model.output.category?.let { model.output.icon(of = it.iconId) },
                    size = 30.dp,
                )
            }

            Hairline()

            SlipRow(
                title = model.output.walletTitle,
                value = model.output.wallet?.name ?: "選ぶ",
                isFromVoice = model.output.isWalletFromVoice,
                isActive = model.state.field == EntryModel.Field.Wallet,
                onSelect = { model.state.focus(EntryModel.Field.Wallet) },
            ) {
                IconTile(
                    icon = model.output.wallet?.let { model.output.icon(of = it.iconId) },
                    size = 30.dp,
                )
            }
        }

        if (model.state.form.type == Entry.Kind.transfer) {
            SlipRow(
                title = "振替",
                value = model.output.routeText,
                isActive = model.state.field in transferFields,
                onSelect = { model.state.focus(EntryModel.Field.Transfer) },
            ) {
                SymbolTile(icon = R.drawable.ic_swap)
            }

            Hairline()

            SlipRow(
                title = "手数料",
                value = if (model.output.fee > 0) AmountText.text(model.output.fee) else "なし",
                isActive = model.state.field == EntryModel.Field.Fee,
                onSelect = { model.state.focus(EntryModel.Field.Fee) },
            ) {
                SymbolTile(icon = R.drawable.ic_bank)
            }
        }

        Hairline()

        SlipRow(
            title = "日付",
            value = model.output.dateValue,
            isFromVoice = model.output.isDateFromVoice,
            isActive = model.state.field == EntryModel.Field.Date,
            onSelect = { model.state.focus(EntryModel.Field.Date) },
        ) {
            DayTile(day = model.state.form.date.day)
        }

        Hairline()

        AmountRow(
            model = model,
            listening = listening,
        )

        Hairline()

        EntrySlipMemoRow(
            model = model,
            onOpenItems = onOpenItems,
            onVoice = onVoice,
        )
    }
}

@Composable
private fun SlipRow(
    title: String,
    value: String,
    isActive: Boolean,
    onSelect: () -> Unit,
    isFromVoice: Boolean = false,
    icon: @Composable () -> Unit,
) {
    EntrySlipActiveRow(
        isActive = isActive,
        modifier = Modifier
            .height(Metrics.rowMinHeight)
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

        FittedText(
            text = value,
            modifier = Modifier.voiceUnderline(isFromVoice),
            color = Palette.text,
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
private fun AmountRow(
    model: EntryModel,
    listening: EntryVoiceFlow.Phase.Listening?,
) {
    val isActive = model.state.field == EntryModel.Field.Amount

    EntrySlipActiveRow(
        isActive = isActive,
        modifier = Modifier
            .height(80.dp)
            .clickable { model.state.focus(EntryModel.Field.Amount) },
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

        val isFee = model.state.field == EntryModel.Field.Fee
        val expression = if (isFee) null else model.output.expressionText

        if (listening != null) {
            EntryVoiceWave(
                levels = listening.levels,
                reach = 2,
                height = 20.dp,
                modifier = Modifier.weight(1f),
            )
        } else {
            FittedText(
                text = expression ?: "",
                modifier = Modifier.weight(1f),
                color = Palette.hint,
                style = textFont(size = FontSize.Caption),
            )
        }

        val amount = listening?.preview?.amount ?: model.output.amount

        AmountText(
            amount = amount,
            style = displayFont(
                size = FontSize.Display,
                weight = FontWeight.Bold,
            ),
            color = if (amount > 0) Palette.accentStrong else Palette.hint,
        )
    }
}

private val transferFields = setOf(
    EntryModel.Field.Transfer,
    EntryModel.Field.Wallet,
    EntryModel.Field.ToWallet,
)
