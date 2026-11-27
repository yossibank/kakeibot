package com.yossibank.kakeibot.features.shared.notice

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.staticCompositionLocalOf
import com.yossibank.kakeibot.featuremodels.shared.model.ErrorNotice
import kotlinx.coroutines.flow.drop

val LocalTabNoticeRound = compositionLocalOf { 0 }
val LocalTabNoticeShown = staticCompositionLocalOf<() -> Unit> { {} }

@Composable
fun TabNoticeRound(notice: ErrorNotice) {
    val round = LocalTabNoticeRound.current
    val start = remember(notice) { round }
    val onShown by rememberUpdatedState(LocalTabNoticeShown.current)

    LaunchedEffect(notice, round) {
        if (round != start) {
            notice.clear()
        }
    }

    LaunchedEffect(notice) {
        snapshotFlow { notice.count }
            .drop(1)
            .collect { onShown() }
    }
}
