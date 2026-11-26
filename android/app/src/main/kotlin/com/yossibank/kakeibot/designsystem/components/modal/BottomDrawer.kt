package com.yossibank.kakeibot.designsystem.components.modal

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.button.CircleIconButton
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity

@Composable
fun <Item : Any> BottomDrawer(
    item: Item?,
    title: (Item) -> String,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    padding: PaddingValues = PaddingValues(16.dp),
    horizontalAlignment: Alignment.Horizontal = Alignment.Start,
    content: @Composable ColumnScope.(Item) -> Unit,
) {
    var last by remember { mutableStateOf(item) }

    if (item != null) {
        last = item
    }

    Scrim(
        isShown = item != null,
        onClose = onClose,
    )

    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.BottomCenter,
    ) {
        AnimatedVisibility(
            visible = item != null,
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            val current = last ?: return@AnimatedVisibility

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(drawerShape)
                    .background(Palette.backgroundTop)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Soft),
                        shape = drawerShape,
                    ).pointerInput(Unit) {}
                    .navigationBarsPadding()
                    .padding(padding),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalAlignment = horizontalAlignment,
            ) {
                DrawerHeader(
                    title = title(current),
                    onClose = onClose,
                )

                content(current)
            }
        }
    }
}

@Composable
private fun Scrim(
    isShown: Boolean,
    onClose: () -> Unit,
) {
    AnimatedVisibility(
        visible = isShown,
        enter = fadeIn(),
        exit = fadeOut(),
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Palette.scrim.opacity(Emphasis.Muted))
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClick = onClose,
                ),
        )
    }
}

@Composable
private fun DrawerHeader(
    title: String,
    onClose: () -> Unit,
) {
    Box(modifier = Modifier.fillMaxWidth()) {
        FittedText(
            text = title,
            modifier = Modifier.align(Alignment.Center),
            color = Palette.accentStrong,
            style = displayFont(size = FontSize.Body),
        )

        CircleIconButton(
            icon = R.drawable.ic_close,
            onClick = onClose,
            modifier = Modifier.align(Alignment.CenterEnd),
        )
    }
}

private val drawerShape = RoundedCornerShape(
    topStart = Metrics.drawerCorner,
    topEnd = Metrics.drawerCorner,
)
