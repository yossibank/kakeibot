package com.yossibank.kakeibot.features.screens.settings.recurrings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont

data class RecurringRow(
    val id: Identifier<Recurring>,
    val title: String,
    val schedule: String,
    val place: String?,
    val amount: Int?,
    val type: Entry.Kind,
    val icon: Icon?,
    val next: LocalDate?,
    val closing: String?,
)

val recurringRowHeight: Dp = 84.dp

@Composable
fun RecurringRowCard(
    row: RecurringRow,
    modifier: Modifier = Modifier,
    isPaused: Boolean = false,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(recurringRowHeight)
            .card()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconTile(
            icon = row.icon,
            size = 38.dp,
        )

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                FittedText(
                    text = row.title,
                    modifier = Modifier.weight(1f),
                    color = Palette.text,
                    style = textFont(style = FontTextStyle.Subheadline),
                )

                if (row.amount != null) {
                    AmountText(
                        amount = row.amount,
                        style = textFont(style = FontTextStyle.Body),
                        type = row.type,
                    )
                } else {
                    Text(
                        text = "利用分",
                        color = Palette.subtext,
                        style = textFont(style = FontTextStyle.Subheadline),
                    )
                }
            }

            FittedText(
                text = row.schedule,
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )

            Row(verticalAlignment = Alignment.CenterVertically) {
                FittedText(
                    text = row.place ?: "",
                    modifier = Modifier.weight(1f),
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption),
                )

                if (isPaused) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.ic_pause),
                            contentDescription = null,
                            modifier = Modifier.size(12.dp),
                            tint = Palette.amber,
                        )

                        Text(
                            text = "止めています",
                            color = Palette.amber,
                            style = textFont(style = FontTextStyle.Caption2),
                        )
                    }
                } else {
                    FittedText(
                        text = nextText(row),
                        color = Palette.subtext,
                        style = textFont(style = FontTextStyle.Caption2),
                    )
                }
            }
        }
    }
}

private fun nextText(row: RecurringRow): String {
    val date = row.next ?: return "終わりました"
    return listOfNotNull(row.closing, "次は ${date.monthDayText}").joinToString("・")
}
