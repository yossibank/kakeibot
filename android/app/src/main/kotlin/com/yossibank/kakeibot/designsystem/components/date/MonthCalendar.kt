package com.yossibank.kakeibot.designsystem.components.date

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.shared.datechoice.shortName

@Composable
fun MonthCalendar(
    selection: LocalDate,
    today: LocalDate,
    onSelect: (LocalDate) -> Unit,
    modifier: Modifier = Modifier,
) {
    var month by remember { mutableStateOf(selection.yearMonth) }

    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            MonthButton(
                rotation = 180f,
                onSelect = { month = month.adding(months = -1) },
            )

            Text(
                text = "${month.year}年 ${month.month}月",
                modifier = Modifier.weight(1f),
                color = Palette.accentStrong,
                textAlign = TextAlign.Center,
                style = displayFont(size = FontSize.Body),
            )

            MonthButton(
                rotation = 0f,
                onSelect = { month = month.adding(months = 1) },
            )
        }

        Row(modifier = Modifier.fillMaxWidth()) {
            Weekday.week(startingOn = Weekday.sunday).forEach { weekday ->
                Text(
                    text = weekday.shortName,
                    modifier = Modifier.weight(1f),
                    color = Palette.subtext,
                    textAlign = TextAlign.Center,
                    style = textFont(size = FontSize.Caption),
                )
            }
        }

        month.weeks(startingOn = Weekday.sunday).forEach { week ->
            Row(modifier = Modifier.fillMaxWidth()) {
                week.forEach { day ->
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center,
                    ) {
                        if (day != null) {
                            DayCell(
                                day = day,
                                isSelected = day == selection,
                                isToday = day == today,
                                onSelect = { onSelect(day) },
                            )
                        } else {
                            Spacer(modifier = Modifier.height(dayCellSize))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MonthButton(
    rotation: Float,
    onSelect: () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier
                .size(22.dp)
                .rotate(rotation),
            tint = Palette.accent,
        )
    }
}

@Composable
private fun DayCell(
    day: LocalDate,
    isSelected: Boolean,
    isToday: Boolean,
    onSelect: () -> Unit,
) {
    val fill = if (isSelected) Palette.accent else Color.Transparent
    val rim = if (isToday && !isSelected) Palette.accent else Color.Transparent

    Box(
        modifier = Modifier
            .size(dayCellSize)
            .clip(CircleShape)
            .background(fill)
            .border(
                width = 1.dp,
                color = rim,
                shape = CircleShape,
            ).clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = day.day.toString(),
            color = if (isSelected) Palette.backgroundTop else Palette.text,
            style = displayFont(size = FontSize.Body),
        )
    }
}

private val dayCellSize: Dp = 36.dp
