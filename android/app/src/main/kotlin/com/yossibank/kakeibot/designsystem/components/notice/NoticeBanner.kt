package com.yossibank.kakeibot.designsystem.components.notice

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask

@Composable
fun NoticeBanner(
    message: String,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Text(
        text = message,
        modifier = modifier
            .fillMaxWidth()
            .card()
            .clickable(onClick = onClose)
            .padding(12.dp),
        color = Palette.rose,
        style = textFont(style = FontTextStyle.Caption),
    )
}

fun LazyListScope.noticeBanner(task: ModelTask) {
    if (task.message.isEmpty()) {
        return
    }

    item(key = "notice") {
        NoticeBanner(
            message = task.message,
            onClose = task::clear,
        )
    }
}
