package com.yossibank.kakeibot.designsystem.components.budget

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.opacity

@Composable
fun BudgetUsageBar(
    usage: BudgetUsage,
    modifier: Modifier = Modifier,
) {
    val progress by animateFloatAsState(
        targetValue = usage.progress.toFloat(),
        label = "budget-progress",
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(6.dp)
            .clip(CircleShape)
            .background(usage.tint.opacity(Emphasis.Faint)),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(progress)
                .fillMaxHeight()
                .clip(CircleShape)
                .background(usage.tint),
        )
    }
}
