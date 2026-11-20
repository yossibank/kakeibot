package com.yossibank.kakeibot.features.screens.settings.period

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.designsystem.components.date.shortName
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.period.PeriodText
import com.yossibank.kakeibot.features.shared.period.title
import com.yossibank.kakeibot.features.shared.settingsparts.ChoiceChip

val MonthStartDay.title: String
    get() = PeriodText.startDay(this)

val Weekday.title: String
    get() = "${shortName}曜日"

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun MonthStartView(
    selection: MonthStartDay,
    today: LocalDate,
    onSelect: (MonthStartDay) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        PeriodCard(
            selection = selection,
            today = today,
        )

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .card()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                MonthStartDay.allDays.forEach { day ->
                    ChoiceChip(
                        title = if (day.isLastDay) "末日" else "${day.day}",
                        isSelected = day.day == selection.day,
                        onSelect = { onSelect(day.shifted(by = selection.shift)) },
                        modifier = Modifier.widthIn(min = 40.dp),
                    )
                }
            }
        }

        ShiftSection(
            selection = selection,
            today = today,
            onSelect = { onSelect(selection.shifted(by = it)) },
        )
    }
}

@Composable
private fun PeriodCard(
    selection: MonthStartDay,
    today: LocalDate,
) {
    val month = today.periodMonth(startingOn = selection)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "いまの期間",
            color = Palette.accent,
            style = textFont(style = FontTextStyle.Caption2),
        )

        Text(
            text = PeriodText.range(month.period(startingOn = selection)),
            color = Palette.accentStrong,
            style = displayFont(size = FontSize.Title),
        )

        Text(
            text = "${month.month}月として数えます",
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )
    }
}

@Composable
private fun ShiftSection(
    selection: MonthStartDay,
    today: LocalDate,
    onSelect: (HolidayShift) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = "土日・祝日のとき",
            color = Palette.accent,
            style = textFont(style = FontTextStyle.Caption2),
        )

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            HolidayShift.entries.forEach { shift ->
                ChoiceChip(
                    title = shift.title,
                    isSelected = selection.shift == shift,
                    onSelect = { onSelect(shift) },
                )
            }
        }

        Text(
            text = shiftNote(
                selection = selection,
                today = today,
            ),
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )
    }
}

private fun shiftNote(
    selection: MonthStartDay,
    today: LocalDate,
): String {
    if (selection.shift == HolidayShift.none) {
        return "土日・祝日でも、そのまま数えます"
    }

    val month = today.periodMonth(startingOn = selection)
    val start = month.period(startingOn = selection).start
    val unshifted = month.period(startingOn = selection.shifted(by = HolidayShift.none)).start

    if (start == unshifted) {
        return "今の期間の始まりは、平日です"
    }

    return "${PeriodText.weekdayDate(unshifted)}を ${PeriodText.weekdayDate(start)}にずらしています"
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
