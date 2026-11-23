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
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.clamped
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import kotlin.math.abs

@Composable
fun RecurringLoanPlan(
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
        val total = model.plannedTotal
        val end = model.scheduledEndDate

        if (total != null && end != null) {
            Row(verticalAlignment = Alignment.Bottom) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    Caption(text = if (model.isEditing) "これから返す額" else "返す総額")

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

        model.finalAmount?.let { finalAmount ->
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
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = note,
                    modifier = Modifier.weight(1f),
                    color = if (model.balanceGap == null) Palette.subtext else Palette.amber,
                    style = textFont(style = FontTextStyle.Caption),
                )

                if (!model.usesAutoCount && model.autoPlan != null) {
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
    val owed = model.loanOwed

    if (model.usesAutoCount && owed != null) {
        return "残高 ${AmountText.text(amount = owed)} から回数と最後の回を出しています"
    }

    val plan = model.autoPlan ?: return null

    model.balanceGap?.let { gap ->
        return "残高と ${AmountText.text(amount = abs(gap).clamped)} ずれています"
    }

    return if (model.plannedTotal == null) "残高から出すと、あと ${plan.count} 回で終わります" else null
}
