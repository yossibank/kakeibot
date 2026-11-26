package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import kotlinx.coroutines.flow.SharingStarted

class ScreenPartsShared(
    parts: ScreenParts,
) {
    private val entryList = SharedObservation(
        values = parts.database.entryListUpdates(),
        started = SharingStarted.WhileSubscribed(
            stopTimeoutMillis = STOP_MILLIS,
            replayExpirationMillis = 0,
        ),
    )

    val parts = ScreenParts(
        database = parts.database,
        clock = parts.clock,
        entryList = entryList.values,
        wait = parts.wait,
    )

    fun stop() {
        entryList.stop()
    }

    private companion object {
        const val STOP_MILLIS = 5_000L
    }
}
