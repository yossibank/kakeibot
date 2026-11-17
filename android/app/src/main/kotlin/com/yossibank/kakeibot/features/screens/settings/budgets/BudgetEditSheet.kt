package com.yossibank.kakeibot.features.screens.settings.budgets

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.writes.methods.setBudget
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

@Composable
fun BudgetEditSheet(
    database: AppDatabase,
    month: YearMonth,
    amount: Int?,
    onClose: () -> Unit,
) {
    var calculator by remember { mutableStateOf(AmountCalculator(amount = amount ?: 0)) }
    var message by remember { mutableStateOf("") }

    val scope = rememberCoroutineScope()

    fun save(value: Int?) {
        scope.launch {
            try {
                database.setBudget(
                    amount = value,
                    categoryId = null,
                    from = month,
                )

                onClose()
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                message = "保存できませんでした"
            }
        }
    }

    BackHandler(onBack = onClose)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Palette.background)
            .pointerInput(Unit) {}
            .statusBarsPadding()
            .navigationBarsPadding()
            .padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "月の予算",
                modifier = Modifier.weight(1f),
                color = Palette.accentStrong,
                style = displayFont(size = FontSize.Headline),
            )

            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Muted),
                        shape = CircleShape,
                    ).clickable(onClick = onClose),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_close),
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Palette.subtext,
                )
            }
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .card()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
            horizontalAlignment = Alignment.End,
        ) {
            Text(
                text = "${month.month}月からの、1 か月に使うお金",
                modifier = Modifier.fillMaxWidth(),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )

            AmountText(
                amount = calculator.amount,
                style = displayFont(
                    size = FontSize.Display,
                    weight = FontWeight.Bold,
                ),
                color = if (calculator.amount > 0) Palette.accentStrong else Palette.hint,
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        Keypad(
            calculator = calculator,
            onKey = {
                calculator = calculator.press(it)
                message = ""
            },
            keyHeight = 56.dp,
        )

        Text(
            text = message,
            color = Palette.rose,
            maxLines = 1,
            style = textFont(size = FontSize.Caption),
        )

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (amount != null) {
                Box(
                    modifier = Modifier
                        .height(52.dp)
                        .clip(CircleShape)
                        .border(
                            width = 1.dp,
                            color = Palette.accent.opacity(Emphasis.Medium),
                            shape = CircleShape,
                        ).clickable { save(null) }
                        .padding(horizontal = 20.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "予算をなくす",
                        color = Palette.accent,
                        style = textFont(
                            size = FontSize.Small,
                            weight = FontWeight.SemiBold,
                        ),
                    )
                }
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(52.dp)
                    .clip(CircleShape)
                    .background(Brush.verticalGradient(listOf(Palette.accentDeep, Palette.accent)))
                    .clickable {
                        if (calculator.amount > 0) {
                            save(calculator.amount)
                        } else {
                            message = "金額を入れてください"
                        }
                    },
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "保存する",
                    color = Palette.backgroundTop,
                    style = textFont(
                        size = FontSize.Body,
                        weight = FontWeight.SemiBold,
                    ),
                )
            }
        }
    }
}
