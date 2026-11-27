package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.autoPlan
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.balanceGap
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.finalAmount
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.loanOwed
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.plannedTotal
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.scheduledEndDate
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.usesAutoCount
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import kotlin.math.abs

@Composable
fun RecurringLoanPlanCard(
    model: RecurringEditModel,
    onMatch: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        val total = model.output.plannedTotal
        val end = model.output.scheduledEndDate

        if (total != null && end != null) {
            Summary(
                title = if (model.flow.output.isEditing) "これから返す額" else "返す総額",
                total = total,
                end = end,
            )
        }

        model.output.finalAmount?.let { finalAmount ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Caption(
                    text = "最後の回",
                    modifier = Modifier.weight(1f),
                )

                AmountText(
                    amount = finalAmount,
                    style = textFont(
                        style = FontTextStyle.Subheadline,
                        weight = FontWeight.SemiBold,
                    ),
                    color = Palette.text,
                )
            }
        }

        noteText(model)?.let { note ->
            Note(
                model = model,
                note = note,
                onMatch = onMatch,
            )
        }
    }
}

@Composable
private fun Summary(
    title: String,
    total: Long,
    end: LocalDate,
) {
    Row(verticalAlignment = Alignment.Bottom) {
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Caption(text = title)

            AmountText(
                amount = total.clamped,
                style = displayFont(
                    size = FontSize.Title,
                    weight = FontWeight.Bold,
                ),
                color = Palette.accentStrong,
            )
        }

        Column(
            verticalArrangement = Arrangement.spacedBy(2.dp),
            horizontalAlignment = Alignment.End,
        ) {
            Caption(text = "終わり")

            Text(
                text = "${end.year}年${end.month}月",
                color = Palette.text,
                style = textFont(
                    style = FontTextStyle.Subheadline,
                    weight = FontWeight.SemiBold,
                ),
            )
        }
    }
}

@Composable
private fun Note(
    model: RecurringEditModel,
    note: String,
    onMatch: () -> Unit,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = note,
            modifier = Modifier.weight(1f),
            color = if (model.output.balanceGap == null) Palette.subtext else Palette.amber,
            style = textFont(style = FontTextStyle.Caption),
        )

        if (!model.output.usesAutoCount && model.output.autoPlan != null) {
            Text(
                text = "合わせる",
                modifier = Modifier.clickable(onClick = onMatch),
                color = Palette.accent,
                style = textFont(
                    size = FontSize.Caption,
                    weight = FontWeight.Bold,
                ),
            )
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
        color = Palette.subtext,
        style = textFont(style = FontTextStyle.Caption),
    )
}

private fun noteText(model: RecurringEditModel): String? {
    val owed = model.output.loanOwed

    if (model.output.usesAutoCount && owed != null) {
        return "残高 ${AmountText.text(amount = owed)} から回数と最後の回を出しています"
    }

    val plan = model.output.autoPlan ?: return null

    model.output.balanceGap?.let { gap ->
        return "残高と ${AmountText.text(amount = abs(gap).clamped)} ずれています"
    }

    return if (model.output.plannedTotal == null) "残高から出すと、あと ${plan.count} 回で終わります" else null
}
