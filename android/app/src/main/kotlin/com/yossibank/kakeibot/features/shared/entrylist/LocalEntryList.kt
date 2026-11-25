package com.yossibank.kakeibot.features.shared.entrylist

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import com.yossibank.kakeibot.featuremodels.shared.model.SharedObservation
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted

val LocalEntryList = staticCompositionLocalOf<Flow<EntryList>?> { null }

@Composable
fun rememberSharedEntryList(database: AppDatabase): Flow<EntryList> {
    val shared = remember(database) {
        val sharing = SharingStarted.WhileSubscribed(
            stopTimeoutMillis = STOP_MILLIS,
            replayExpirationMillis = 0,
        )

        SharedObservation(
            values = database.entryListUpdates(),
            started = sharing,
        )
    }

    DisposableEffect(shared) {
        onDispose { shared.stop() }
    }

    return shared.values
}

@Composable
fun rememberEntryList(database: AppDatabase): Flow<EntryList> {
    val shared = LocalEntryList.current
    return remember(database, shared) { shared ?: database.entryListUpdates() }
}

private const val STOP_MILLIS = 5_000L
