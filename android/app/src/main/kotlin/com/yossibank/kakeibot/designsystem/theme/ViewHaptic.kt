package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import kotlinx.coroutines.flow.drop

enum class Haptic(
    internal val type: HapticFeedbackType,
) {
    Selection(HapticFeedbackType.TextHandleMove),
    Impact(HapticFeedbackType.LongPress),
    LightImpact(HapticFeedbackType.ContextClick),
}

@Composable
fun <Trigger> HapticEffect(
    haptic: Haptic,
    trigger: Trigger,
) {
    val feedback = LocalHapticFeedback.current
    val isOn = LocalThemeStyle.current.haptics
    val current = rememberUpdatedState(trigger)

    LaunchedEffect(feedback, isOn, haptic) {
        snapshotFlow { current.value }
            .drop(1)
            .collect {
                if (isOn) {
                    feedback.performHapticFeedback(haptic.type)
                }
            }
    }
}
