package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import kotlin.math.roundToInt

@Composable
fun RecurringHiddenSection(
    rows: List<RecurringRow>,
    isOpen: Boolean,
    onToggle: () -> Unit,
    onDeleteAll: () -> Unit,
    onEdit: (Identifier<Recurring>) -> Unit,
    onShow: (Identifier<Recurring>) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = 32.dp)
                        .clickable(onClick = onToggle),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        painter = painterResource(R.drawable.ic_chevron_right),
                        contentDescription = null,
                        modifier = Modifier
                            .size(16.dp)
                            .rotate(if (isOpen) 90f else 0f),
                        tint = Palette.accent,
                    )

                    Text(
                        text = "非表示の固定費（${rows.size}）",
                        color = Palette.accent,
                        style = textFont(
                            style = FontTextStyle.Caption,
                            weight = FontWeight.SemiBold,
                        ),
                    )
                }

                if (isOpen) {
                    Row(
                        modifier = Modifier
                            .heightIn(min = 32.dp)
                            .clickable(onClick = onDeleteAll),
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.ic_trash),
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = Palette.rose,
                        )

                        Text(
                            text = "まとめて削除",
                            color = Palette.rose,
                            style = textFont(style = FontTextStyle.Caption),
                        )
                    }
                }
            }

            if (isOpen) {
                Text(
                    text = "長押しで上に動かすと戻せます",
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption2),
                )
            }
        }

        if (isOpen) {
            rows.forEach { row ->
                HiddenRow(
                    row = row,
                    onEdit = { onEdit(row.id) },
                    onShow = { onShow(row.id) },
                )
            }
        }
    }
}

@Composable
private fun HiddenRow(
    row: RecurringRow,
    onEdit: () -> Unit,
    onShow: () -> Unit,
) {
    var dragY by remember { mutableFloatStateOf(0f) }
    val reach = with(LocalDensity.current) { recurringRowHeight.toPx() }

    RecurringRowCard(
        row = row,
        isPaused = true,
        modifier = Modifier
            .zIndex(if (dragY != 0f) 1f else 0f)
            .offset { IntOffset(0, dragY.roundToInt()) }
            .alpha(if (dragY != 0f) 1f else 0.5f)
            .clickable(onClick = onEdit)
            .pointerInput(row.id) {
                detectDragGesturesAfterLongPress(
                    onDragEnd = {
                        if (dragY < -reach) {
                            onShow()
                        }

                        dragY = 0f
                    },
                    onDragCancel = { dragY = 0f },
                ) { change, amount ->
                    change.consume()
                    dragY = minOf(dragY + amount.y, 0f)
                }
            },
    )
}
