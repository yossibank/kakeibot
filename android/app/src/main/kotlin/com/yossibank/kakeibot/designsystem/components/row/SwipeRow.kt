package com.yossibank.kakeibot.designsystem.components.row

import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

@Composable
fun <ID> SwipeRow(
    id: ID,
    openId: ID?,
    onOpen: (ID?) -> Unit,
    onTap: () -> Unit,
    onHide: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
    contentModifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val offset = remember { Animatable(0f) }
    val reach = with(LocalDensity.current) { (actionWidth * 2 + 8.dp).toPx() }

    LaunchedEffect(openId) {
        if (openId != id && offset.value != 0f) {
            offset.animateTo(0f)
        }
    }

    fun settle(isOpen: Boolean) {
        scope.launch { offset.animateTo(if (isOpen) -reach else 0f) }
        onOpen(if (isOpen) id else null)
    }

    Box(modifier = modifier.height(IntrinsicSize.Min)) {
        SwipeActions(
            opacity = { (-offset.value / reach).coerceIn(0f, 1f) },
            onClose = { settle(isOpen = false) },
            onDelete = onDelete,
            onHide = onHide,
        )

        Box(
            modifier = Modifier
                .offset { IntOffset(offset.value.roundToInt(), 0) }
                .pointerInput(reach) {
                    detectHorizontalDragGestures(
                        onDragEnd = { settle(isOpen = offset.value < -reach / 2) },
                        onDragCancel = { settle(isOpen = false) },
                    ) { change, amount ->
                        change.consume()
                        scope.launch {
                            offset.snapTo((offset.value + amount).coerceIn(-reach, 0f))
                        }
                    }
                }.clickable {
                    if (offset.value != 0f) {
                        settle(isOpen = false)
                    } else {
                        onTap()
                    }
                }.then(contentModifier),
        ) {
            content()
        }
    }
}

@Composable
private fun BoxScope.SwipeActions(
    opacity: () -> Float,
    onClose: () -> Unit,
    onDelete: () -> Unit,
    onHide: () -> Unit,
) {
    Row(
        modifier = Modifier
            .align(Alignment.CenterEnd)
            .fillMaxHeight()
            .graphicsLayer { alpha = opacity() },
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Action(
            title = "削除",
            icon = R.drawable.ic_trash,
            color = Palette.rose,
            onSelect = {
                onClose()
                onDelete()
            },
        )

        Action(
            title = "非表示",
            icon = R.drawable.ic_pause,
            color = Palette.amber,
            onSelect = {
                onClose()
                onHide()
            },
        )
    }
}

@Composable
private fun Action(
    title: String,
    icon: Int,
    color: Color,
    onSelect: () -> Unit,
) {
    Column(
        modifier = Modifier
            .width(actionWidth)
            .fillMaxHeight()
            .clip(RoundedCornerShape(20.dp))
            .background(color)
            .clickable(onClick = onSelect)
            .padding(4.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            painter = painterResource(icon),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = Palette.backgroundTop,
        )

        Text(
            text = title,
            color = Palette.backgroundTop,
            style = textFont(
                size = FontSize.Caption,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

private val actionWidth = 76.dp
