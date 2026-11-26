package com.yossibank.kakeibot.features.shared.notice

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.staticCompositionLocalOf
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import kotlinx.coroutines.flow.drop

val LocalTabNoticeRound = compositionLocalOf { 0 }

val LocalTabNoticeShown = staticCompositionLocalOf<() -> Unit> { {} }

@Composable
fun TabNoticeRound(task: ModelTask) {
    val round = LocalTabNoticeRound.current
    val start = remember(task) { round }
    val onShown by rememberUpdatedState(LocalTabNoticeShown.current)

    LaunchedEffect(task, round) {
        if (round != start) {
            task.clear()
        }
    }

    LaunchedEffect(task) {
        snapshotFlow { task.count }
            .drop(1)
            .collect { onShown() }
    }
}
