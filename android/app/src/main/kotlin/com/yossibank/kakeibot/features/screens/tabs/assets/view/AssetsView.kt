package com.yossibank.kakeibot.features.screens.tabs.assets.view

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.components.text.clamped
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.settings.wallets.title
import com.yossibank.kakeibot.features.screens.tabs.assets.model.AssetsModel
import com.yossibank.kakeibot.features.shared.entrylist.rememberEntryList
import com.yossibank.kakeibot.store.database.AppDatabase

@Composable
fun AssetsView(database: AppDatabase) {
    val entryList = rememberEntryList(database)
    val model = remember(entryList) { AssetsModel(entryList = entryList) }

    LaunchedEffect(model) {
        model.observe()
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            start = 16.dp,
            top = 12.dp,
            end = 16.dp,
            bottom = 24.dp,
        ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item(key = "title") {
            Text(
                text = "資産",
                color = Palette.accentStrong,
                style = displayFont(size = FontSize.Headline),
            )
        }

        item(key = "total") {
            TotalCard(model = model)
        }

        if (model.assets.isNotEmpty()) {
            item(key = "assets") {
                WalletCard(
                    title = "資産",
                    rows = model.assets,
                )
            }
        }

        if (model.debts.isNotEmpty()) {
            item(key = "debts") {
                WalletCard(
                    title = "負債",
                    rows = model.debts,
                )
            }
        }
    }
}

@Composable
private fun TotalCard(model: AssetsModel) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Caption(text = "手元のお金")

        AmountText(
            amount = model.onHand.clamped,
            style = displayFont(
                size = FontSize.LargeTitle,
                weight = FontWeight.Bold,
            ),
            color = if (model.onHand < 0) Palette.rose else Palette.accentStrong,
        )

        Hairline()

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "純資産",
                modifier = Modifier.weight(1f),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )

            AmountText(
                amount = model.netWorth.clamped,
                style = displayFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
                color = if (model.netWorth < 0) Palette.rose else Palette.text,
            )
        }
    }
}

@Composable
private fun WalletCard(
    title: String,
    rows: List<AssetsModel.Row>,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(horizontal = 16.dp)
            .padding(
                top = 12.dp,
                bottom = 4.dp,
            ),
    ) {
        Caption(
            text = title,
            modifier = Modifier.padding(bottom = 8.dp),
        )

        rows.forEach { row ->
            Hairline()

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 56.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconTile(
                    icon = row.icon,
                    size = 32.dp,
                )

                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    FittedText(
                        text = row.name,
                        color = Palette.text,
                        style = textFont(style = FontTextStyle.Subheadline),
                    )

                    Text(
                        text = row.kind.title,
                        color = Palette.subtext,
                        style = textFont(style = FontTextStyle.Caption),
                    )
                }

                AmountText(
                    amount = row.balance.clamped,
                    style = displayFont(size = FontSize.Body),
                    color = if (row.balance < 0) Palette.rose else Palette.text,
                )
            }
        }
    }
}

@Composable
private fun Caption(
    text: String,
    modifier: Modifier = Modifier,
) {
    Text(
        text = text,
        modifier = modifier,
        color = Palette.accent,
        style = textFont(
            style = FontTextStyle.Caption,
            weight = FontWeight.SemiBold,
        ),
    )
}

@Composable
private fun Hairline() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(Palette.line),
    )
}
