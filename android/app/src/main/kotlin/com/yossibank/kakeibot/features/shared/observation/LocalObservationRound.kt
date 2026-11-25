package com.yossibank.kakeibot.features.shared.observation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound

val LocalObservationRound = staticCompositionLocalOf<ObservationRound?> { null }

@Composable
fun rememberObservationRound(): ObservationRound {
    val shared = LocalObservationRound.current
    return remember(shared) { shared ?: ObservationRound() }
}
