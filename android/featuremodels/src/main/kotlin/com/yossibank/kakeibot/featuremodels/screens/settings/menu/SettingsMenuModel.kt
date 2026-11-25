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
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

class SettingsMenuModel(
    database: AppDatabase,
) : SettingsFoldModel {
    val state = State()
    val input = Input()

    private val dependencies = Dependencies(database)

    class State {
        val task = ModelTask()
    }

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
                follow(
                    values = database.settingUpdates(SettingKey.monthStartDay),
                    fallback = MonthStartDay.first,
                ) { input.monthStartDay = it }
            }

            launch {
                follow(
                    values = database.settingUpdates(SettingKey.weekStart),
                    fallback = Weekday.monday,
                ) { input.weekStart = it }
            }

            follow(
                values = database.recurringUpdates(),
                fallback = emptyList(),
            ) { input.recurringCount = it.size }
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
        state.task.attempt(failure = ModelTask.settingSaveFailed) {
            dependencies.database.setSetting(
                key = key,
                to = value,
            )
        }
    }

    private suspend fun <Value> follow(
        values: Flow<Value>,
        fallback: Value,
        receive: (Value) -> Unit,
    ) {
        ModelTask.quiet { values.collect { receive(it) } } ?: receive(fallback)
    }
}
