package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.row.SwipeRow
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringListModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringRow
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import kotlin.math.roundToInt

private val rowSpacing = 12.dp

data class RecurringRowActions(
    val onOpen: (Identifier<Recurring>?) -> Unit,
    val onEdit: (Identifier<Recurring>) -> Unit,
    val onHide: (Identifier<Recurring>) -> Unit,
    val onDelete: (Identifier<Recurring>) -> Unit,
)

@Composable
fun RecurringBoard(
    model: RecurringListModel,
    lift: RecurringLift,
    openId: Identifier<Recurring>?,
    actions: RecurringRowActions,
    modifier: Modifier = Modifier,
) {
    val rows = model.output.rows

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(recurringRowHeight * rows.size + rowSpacing * maxOf(rows.size - 1, 0))
            .onGloballyPositioned { lift.origin = it.positionInRoot() },
    ) {
        rows.forEachIndexed { index, row ->
            key(row.id) {
                BoardRow(
                    model = model,
                    lift = lift,
                    row = row,
                    index = index,
                    openId = openId,
                    actions = actions,
                )
            }
        }
    }
}

@Composable
fun RecurringHideTarget(
    lift: RecurringLift,
    modifier: Modifier = Modifier,
) {
    val fill = if (lift.isOverHide) Palette.amber else Palette.amber.opacity(Emphasis.Soft)
    val text = if (lift.isOverHide) Palette.backgroundTop else Palette.amber

    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(Metrics.buttonHeight)
            .clip(CircleShape)
            .background(fill)
            .onGloballyPositioned { lift.hideTarget = it.boundsInRoot() },
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_pause),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = text,
        )

        Text(
            text = "ここで離すと止めて非表示",
            color = text,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun BoardRow(
    model: RecurringListModel,
    lift: RecurringLift,
    row: RecurringRow,
    index: Int,
    openId: Identifier<Recurring>?,
    actions: RecurringRowActions,
) {
    val slot = with(LocalDensity.current) { (recurringRowHeight + rowSpacing).toPx() }

    val isLifted = lift.id == row.id
    val target by animateDpAsState(
        targetValue = (recurringRowHeight + rowSpacing) * index,
        label = "recurring-row",
    )

    SwipeRow(
        id = row.id,
        openId = openId,
        onOpen = actions.onOpen,
        onTap = { actions.onEdit(row.id) },
        onHide = { actions.onHide(row.id) },
        onDelete = { actions.onDelete(row.id) },
        modifier = Modifier
            .zIndex(if (isLifted) 1f else 0f)
            .offset {
                val y = if (isLifted) lift.y else target.toPx()
                IntOffset(0, y.roundToInt())
            }.scale(if (isLifted) 1.03f else 1f),
        contentModifier = Modifier
            .pointerInput(row.id) {
                detectDragGesturesAfterLongPress(
                    onDragStart = { touch ->
                        actions.onOpen(null)

                        lift.start(
                            id = row.id,
                            top = model.output.rows.indexOfFirst { it.id == row.id } * slot,
                            touch = touch,
                        )
                    },
                    onDragEnd = {
                        val hiding = lift.end()

                        if (hiding != null) {
                            model.state.cancelMoving()
                            actions.onHide(hiding)
                        } else {
                            model.perform { it.finishMoving() }
                        }
                    },
                    onDragCancel = {
                        lift.cancel()
                        model.state.cancelMoving()
                    },
                ) { change, amount ->
                    change.consume()

                    val position = lift.drag(
                        amount = amount,
                        slot = slot,
                    )

                    model.move(row.id, to = position)
                }
            },
    ) {
        RecurringRowCard(row = row)
    }
}
