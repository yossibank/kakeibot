package com.yossibank.kakeibot.features.screens.settings.menu

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.features.shared.model.ModelTask
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.recurringUpdates
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

class SettingsMenuModel(
    private val database: AppDatabase,
) {
    var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)
        private set

    var weekStart: Weekday by mutableStateOf(Weekday.monday)
        private set

    var recurringCount: Int by mutableIntStateOf(0)
        private set

    suspend fun observe() {
        coroutineScope {
            launch {
                database.settingUpdates(SettingKey.monthStartDay).collect { monthStartDay = it }
            }

            launch {
                database.settingUpdates(SettingKey.weekStart).collect { weekStart = it }
            }

            database.recurringUpdates().collect { recurringCount = it.size }
        }
    }

    suspend fun <Value> store(
        key: SettingKey<Value>,
        value: Value,
    ) {
        ModelTask.quiet {
            database.setSetting(
                key = key,
                to = value,
            )
        }
    }
}
