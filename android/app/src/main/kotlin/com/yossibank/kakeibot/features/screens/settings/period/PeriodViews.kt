package com.yossibank.kakeibot.features.screens.settings.period

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.designsystem.components.date.shortName
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.settingsparts.ChoiceChip

val MonthStartDay.title: String
    get() = if (isLastDay) "末日" else "$day 日"

val Weekday.title: String
    get() = "${shortName}曜日"

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun MonthStartView(
    selection: MonthStartDay,
    onSelect: (MonthStartDay) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = "給料日などに合わせると、その日から 1 か月を「今月」として数えます。",
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Footnote),
        )

        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            MonthStartDay.allDays.forEach { day ->
                ChoiceChip(
                    title = day.title,
                    isSelected = day.day == selection.day,
                    onSelect = { onSelect(day.shifted(by = selection.shift)) },
                    modifier = Modifier.widthIn(min = 64.dp),
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun WeekStartView(
    selection: Weekday,
    onSelect: (Weekday) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = "カレンダーの左端の曜日と、振り返りの 1 週間の区切りに使います。",
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Footnote),
        )

        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Weekday.week(startingOn = Weekday.sunday).forEach { weekday ->
                ChoiceChip(
                    title = weekday.title,
                    isSelected = weekday == selection,
                    onSelect = { onSelect(weekday) },
                )
            }
        }
    }
}
