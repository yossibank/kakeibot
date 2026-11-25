package com.yossibank.kakeibot.featuremodels.shared.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import kotlinx.coroutines.flow.collectLatest

class ObservationRound {
    var count: Int by mutableIntStateOf(0)
        private set

    fun restart() {
        count += 1
    }

    suspend fun each(observe: suspend () -> Unit) {
        snapshotFlow { count }.collectLatest { observe() }
    }
}
