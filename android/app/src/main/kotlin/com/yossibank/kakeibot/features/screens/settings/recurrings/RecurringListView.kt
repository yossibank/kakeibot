package com.yossibank.kakeibot.features.screens.settings.recurrings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.nextDate
import com.yossibank.kakeibot.core.concepts.recurring.title
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.settingsparts.RoundIconButton
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHeader
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.categoryListUpdates
import com.yossibank.kakeibot.store.queries.methods.recurringUpdates

@Composable
fun RecurringListView(
    database: AppDatabase,
    today: LocalDate,
    onBack: () -> Unit,
    onEdit: (Recurring?) -> Unit,
) {
    val recurrings by remember(database) { database.recurringUpdates() }
        .collectAsState(initial = emptyList())

    val categories by remember(database) { database.categoryListUpdates() }
        .collectAsState(initial = null)

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SettingsHeader(
            title = "固定費",
            isRoot = false,
            onBack = onBack,
        ) {
            RoundIconButton(
                icon = R.drawable.ic_add,
                onSelect = { onEdit(null) },
            )
        }

        if (recurrings.isEmpty()) {
            Text(
                text = "家賃やサブスクなど、決まった日に出入りするお金を入れておくと、その日に自動で記録します。",
                modifier = Modifier
                    .fillMaxWidth()
                    .card()
                    .padding(16.dp),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Subheadline),
            )
        } else {
            Column(
                modifier = Modifier
                    .weight(1f, fill = false)
                    .fillMaxWidth()
                    .card()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp),
            ) {
                recurrings.forEachIndexed { index, recurring ->
                    val category = categories?.categories?.firstOrNull {
                        it.id ==
                            recurring.categoryId
                    }
                    val recorded = recurring.generatedUntil?.adding(days = 1) ?: today
                    val next = recurring.nextDate(onOrAfter = maxOf(recorded, today))

                    val schedule = Recurring.scheduleText(
                        frequency = recurring.frequency,
                        month = recurring.month,
                        day = recurring.day,
                    )

                    if (index > 0) {
                        SettingsDivider()
                    }

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 60.dp)
                            .clickable { onEdit(recurring) },
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        IconTile(
                            icon = category?.let { categories?.icons?.get(it.iconId) },
                            size = 32.dp,
                        )

                        Column(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(2.dp),
                        ) {
                            Text(
                                text = recurring.title(categoryName = category?.name) ?: "固定費",
                                color = Palette.text,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                style = textFont(style = FontTextStyle.Subheadline),
                            )

                            Text(
                                text = listOfNotNull(
                                    schedule,
                                    next?.let { "次は ${it.monthDayText}" },
                                ).joinToString("・"),
                                color = Palette.subtext,
                                maxLines = 1,
                                style = textFont(style = FontTextStyle.Caption),
                            )
                        }

                        AmountText(
                            amount = recurring.amount,
                            style = displayFont(size = FontSize.Body),
                            type = recurring.type,
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun SaveBar(
    title: String,
    onSave: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(CircleShape)
            .background(Brush.verticalGradient(listOf(Palette.accentDeep, Palette.accent)))
            .clickable(onClick = onSave),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            color = Palette.backgroundTop,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}
