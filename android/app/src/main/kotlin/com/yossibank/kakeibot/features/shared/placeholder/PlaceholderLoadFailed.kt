package com.yossibank.kakeibot.features.shared.placeholder

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun PlaceholderLoadFailed(
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(
            space = 8.dp,
            alignment = Alignment.CenterVertically,
        ),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "読めませんでした",
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Footnote),
        )

        Box(
            modifier = Modifier
                .heightIn(min = 44.dp)
                .clip(CircleShape)
                .clickable(onClick = onRetry)
                .padding(horizontal = 16.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "もう一度読み込む",
                color = Palette.accent,
                style = textFont(style = FontTextStyle.Caption),
            )
        }
    }
}

@Composable
fun LoadFailedColumn(
    isFailed: Boolean,
    onRetry: () -> Unit,
    content: LazyListScope.() -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            start = 16.dp,
            top = 12.dp,
            end = 16.dp,
            bottom = 24.dp,
        ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (isFailed) {
            item(key = "loadFailed") {
                PlaceholderLoadFailed(
                    onRetry = onRetry,
                    modifier = Modifier.fillParentMaxHeight(),
                )
            }
        } else {
            content()
        }
    }
}
