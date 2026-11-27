package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.amount
import com.yossibank.kakeibot.featuremodels.screens.entry.model.loanRemaining
import com.yossibank.kakeibot.featuremodels.screens.entry.model.payOffLoan
import com.yossibank.kakeibot.featuremodels.screens.entry.model.recentTransfers

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
