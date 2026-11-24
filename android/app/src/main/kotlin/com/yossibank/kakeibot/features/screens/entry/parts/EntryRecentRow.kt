package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
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
import com.yossibank.kakeibot.featuremodels.screens.entry.model.apply
import com.yossibank.kakeibot.featuremodels.screens.entry.model.applyRecent
import com.yossibank.kakeibot.featuremodels.screens.entry.model.applyTransfer
import com.yossibank.kakeibot.featuremodels.screens.entry.model.category
import com.yossibank.kakeibot.featuremodels.screens.entry.model.icon
import com.yossibank.kakeibot.featuremodels.screens.entry.model.recentEntries
import com.yossibank.kakeibot.featuremodels.screens.entry.model.recentTransfers
import com.yossibank.kakeibot.featuremodels.screens.entry.model.templates
import com.yossibank.kakeibot.featuremodels.screens.entry.model.wallet
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.core.concepts.icon.Icon as EntryIcon

@Composable
fun EntryRecentRow(
    model: EntryModel,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(
            text = if (model.state.form.type == Entry.Kind.transfer) "最近の振替" else "よく使う",
            modifier = Modifier.padding(horizontal = 4.dp),
            color = Palette.subtext,
            style = textFont(
                size = FontSize.Caption,
                weight = FontWeight.Bold,
            ),
        )

        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            if (model.state.form.type == Entry.Kind.transfer) {
                model.output.recentTransfers.forEach { transfer ->
                    TransferCard(
                        model = model,
                        transfer = transfer,
                    )
                }
            } else {
                model.output.templates.forEach { template ->
                    TemplateCard(
                        model = model,
                        template = template,
                    )
                }

                model.output.recentEntries.forEach { entry ->
                    EntryCard(
                        model = model,
                        entry = entry,
                    )
                }
            }
        }
    }
}

@Composable
private fun TemplateCard(
    model: EntryModel,
    template: EntryTemplate,
) {
    val category = model.output.category(of = template.categoryId)

    RecentCard(
        title = template.name,
        amount = template.amount,
        detail = detail(
            category = category?.name,
            wallet = model.output.wallet(of = template.walletId)?.name,
        ),
        icon = category?.let { model.output.icon(of = it.iconId) },
        isPinned = true,
        onUse = { model.apply(template) },
    )
}

@Composable
private fun EntryCard(
    model: EntryModel,
    entry: Entry,
) {
    val category = model.output.category(of = entry.categoryId)
    val memo = entry.memo?.takeIf { it.isNotEmpty() }

    RecentCard(
        title = memo ?: category?.name ?: "",
        amount = entry.amount,
        detail = detail(
            category = if (memo == null) null else category?.name,
            wallet = model.output.wallet(of = entry.walletId)?.name,
        ),
        icon = category?.let { model.output.icon(of = it.iconId) },
        isPinned = false,
        onUse = { model.applyRecent(entry) },
    )
}

@Composable
private fun TransferCard(
    model: EntryModel,
    transfer: Entry,
) {
    val source = model.output.wallet(of = transfer.walletId)

    RecentCard(
        title = source?.name ?: "",
        amount = transfer.amount,
        detail = "→ ${model.output.wallet(of = transfer.toWalletId)?.name ?: ""}",
        icon = source?.let { model.output.icon(of = it.iconId) },
        isPinned = false,
        onUse = { model.applyTransfer(transfer) },
    )
}

@Composable
private fun RecentCard(
    title: String,
    amount: Int?,
    detail: String,
    icon: EntryIcon?,
    isPinned: Boolean,
    onUse: () -> Unit,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(16.dp))

    Row(
        modifier = Modifier
            .height(48.dp)
            .widthIn(max = 240.dp)
            .clip(shape)
            .background(Palette.card)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Soft),
                shape = shape,
            ).clickable(onClick = onUse)
            .padding(
                start = 8.dp,
                end = 12.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconTile(
            icon = icon,
            size = 32.dp,
        )

        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (isPinned) {
                    Icon(
                        painter = painterResource(R.drawable.ic_pin),
                        contentDescription = null,
                        modifier = Modifier.size(12.dp),
                        tint = Palette.accent,
                    )
                }

                FittedText(
                    text = title,
                    color = Palette.text,
                    style = textFont(
                        size = FontSize.Caption,
                        weight = FontWeight.Bold,
                    ),
                )
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                FittedText(
                    text = detail,
                    color = Palette.subtext,
                    modifier = Modifier.weight(1f, fill = false),
                    style = textFont(size = FontSize.Micro),
                )

                Spacer(modifier = Modifier.size(8.dp))

                if (amount != null) {
                    FittedText(
                        text = AmountText.text(amount),
                        color = Palette.accentStrong,
                        style = displayFont(
                            size = FontSize.Small,
                            weight = FontWeight.SemiBold,
                        ),
                    )
                } else {
                    FittedText(
                        text = "毎回入れる",
                        color = Palette.hint,
                        style = textFont(
                            size = FontSize.Micro,
                            weight = FontWeight.SemiBold,
                        ),
                    )
                }
            }
        }
    }
}

private fun detail(
    category: String?,
    wallet: String?,
): String = listOfNotNull(category, wallet).joinToString("・")
