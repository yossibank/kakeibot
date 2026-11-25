package com.yossibank.kakeibot.featuremodels.shared.model

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted

class SharedObservation<Value>(
    values: Flow<Value>,
    started: SharingStarted,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    val values: Flow<Value> = ScreenObservation.share(
        values = values,
        scope = scope,
        started = started,
    )

    fun stop() {
        scope.cancel()
    }
}
