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
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.model.apply
import com.yossibank.kakeibot.features.screens.entry.model.applyRecent
import com.yossibank.kakeibot.features.screens.entry.model.applyTransfer
import com.yossibank.kakeibot.features.screens.entry.model.categoryText
import com.yossibank.kakeibot.features.screens.entry.model.dateText
import com.yossibank.kakeibot.features.screens.entry.model.expressionText
import com.yossibank.kakeibot.features.screens.entry.model.isDateFromVoice
import com.yossibank.kakeibot.features.screens.entry.model.isMemoFromVoice
import com.yossibank.kakeibot.features.screens.entry.model.isWalletFromVoice
import com.yossibank.kakeibot.features.screens.entry.model.itemAdjustment
import com.yossibank.kakeibot.features.screens.entry.model.itemTotal
import com.yossibank.kakeibot.features.screens.entry.model.newTemplateDraft
import com.yossibank.kakeibot.features.screens.entry.model.routeText
import com.yossibank.kakeibot.features.screens.entry.model.showsItems
import com.yossibank.kakeibot.features.screens.entry.model.walletTitle
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceFlow
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
        if (model.form.type != Entry.Kind.transfer) {
            SlipRow(
                title = "カテゴリ",
                value = preview?.categoryId
                    ?.let { id -> model.categories.firstOrNull { it.id == id }?.name }
                    ?: model.categoryText,
                isActive = model.field == EntryModel.Field.Category,
                onSelect = { model.focus(EntryModel.Field.Category) },
            ) {
                IconTile(
                    icon = model.category?.let { model.icon(of = it.iconId) },
                    size = 30.dp,
                )
            }

            Hairline()

            SlipRow(
                title = model.walletTitle,
                value = model.wallet?.name ?: "選ぶ",
                isFromVoice = model.isWalletFromVoice,
                isActive = model.field == EntryModel.Field.Wallet,
                onSelect = { model.focus(EntryModel.Field.Wallet) },
            ) {
                IconTile(
                    icon = model.wallet?.let { model.icon(of = it.iconId) },
                    size = 30.dp,
                )
            }
        }

        if (model.form.type == Entry.Kind.transfer) {
            SlipRow(
                title = "振替",
                value = model.routeText,
                isActive = model.field in transferFields,
                onSelect = { model.focus(EntryModel.Field.Transfer) },
            ) {
                SymbolTile(icon = R.drawable.ic_swap)
            }

            Hairline()

            SlipRow(
                title = "手数料",
                value = if (model.fee > 0) AmountText.text(model.fee) else "なし",
                isActive = model.field == EntryModel.Field.Fee,
                onSelect = { model.focus(EntryModel.Field.Fee) },
            ) {
                SymbolTile(icon = R.drawable.ic_bank)
            }
        }

        Hairline()

        SlipRow(
            title = "日付",
            value = model.dateText,
            isFromVoice = model.isDateFromVoice,
            isActive = model.field == EntryModel.Field.Date,
            onSelect = { model.focus(EntryModel.Field.Date) },
        ) {
            DayTile(day = model.form.date.day)
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

        Text(
            text = value,
            modifier = Modifier.voiceUnderline(isFromVoice),
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
private fun AmountRow(
    model: EntryModel,
    listening: EntryVoiceFlow.Phase.Listening?,
) {
    val isActive = model.field == EntryModel.Field.Amount

    EntrySlipActiveRow(
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

        val expression = if (model.field == EntryModel.Field.Fee) null else model.expressionText

        if (listening != null) {
            EntryVoiceWave(
                levels = listening.levels,
                reach = 2,
                height = 20.dp,
                modifier = Modifier.weight(1f),
            )
        } else {
            Text(
                text = expression ?: "",
                modifier = Modifier.weight(1f),
                color = Palette.hint,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                style = textFont(size = FontSize.Caption),
            )
        }

        val amount = listening?.preview?.amount ?: model.amount

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
