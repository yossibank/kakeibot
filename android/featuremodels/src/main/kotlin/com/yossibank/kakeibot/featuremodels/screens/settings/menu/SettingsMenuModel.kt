package com.yossibank.kakeibot.featuremodels.screens.settings.menu

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldInput
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldModel
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
    database: AppDatabase,
) : SettingsFoldModel {
    val input = Input()

    private val dependencies = Dependencies(database)

    class Input {
        var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)
            internal set

        var weekStart: Weekday by mutableStateOf(Weekday.monday)
            internal set

        var recurringCount: Int by mutableIntStateOf(0)
            internal set

        val monthStartHint = SettingsFoldInput.hint(SettingsScreen.monthStartDay)
    }

    private class Dependencies(
        val database: AppDatabase,
    )

    suspend fun observe() {
        val database = dependencies.database

        coroutineScope {
            launch {
                database.settingUpdates(SettingKey.monthStartDay).collect {
                    input.monthStartDay = it
                }
            }

            launch {
                database.settingUpdates(SettingKey.weekStart).collect { input.weekStart = it }
            }

            database.recurringUpdates().collect { input.recurringCount = it.size }
        }
    }

    override suspend fun loadFold(fold: SettingsFoldInput) {
        fold.load(from = dependencies.database)
    }

    override suspend fun setFold(
        fold: SettingsFoldInput,
        isClosed: Boolean,
    ) {
        fold.save(
            isClosed = isClosed,
            to = dependencies.database,
        )
    }

    suspend fun <Value> store(
        key: SettingKey<Value>,
        value: Value,
    ) {
        ModelTask.quiet {
            dependencies.database.setSetting(
                key = key,
                to = value,
            )
        }
    }
}
