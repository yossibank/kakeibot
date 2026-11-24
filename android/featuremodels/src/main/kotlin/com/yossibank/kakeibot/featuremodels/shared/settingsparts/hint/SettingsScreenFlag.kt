package com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.closedHiddenLists
import com.yossibank.kakeibot.store.records.settingkeys.closedHints
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.CancellationException

class SettingsScreenFlag(
    private val database: AppDatabase,
    private val key: SettingKey<Set<SettingsScreen>>,
    private val screen: SettingsScreen,
    isOn: Boolean = false,
    private val savesOn: Boolean = true,
) {
    var isOn: Boolean by mutableStateOf(isOn)
        private set

    var isLoaded: Boolean by mutableStateOf(false)
        private set

    suspend fun load() {
        val screens = read() ?: emptySet()

        isOn = (screen in screens) == savesOn
        isLoaded = true
    }

    suspend fun set(isOn: Boolean) {
        this.isOn = isOn

        val screens = read()?.toMutableSet() ?: mutableSetOf()

        if (isOn == savesOn) {
            screens.add(screen)
        } else {
            screens.remove(screen)
        }

        ModelTask.quiet {
            database.setSetting(
                key = key,
                to = screens,
            )
        }
    }

    private suspend fun read(): Set<SettingsScreen>? = ModelTask.quiet { database.setting(key) }

    companion object {
        fun closedHint(
            screen: SettingsScreen,
            database: AppDatabase,
        ): SettingsScreenFlag = SettingsScreenFlag(
            database = database,
            key = SettingKey.closedHints,
            screen = screen,
            isOn = true,
        )

        fun openHiddenList(
            screen: SettingsScreen,
            database: AppDatabase,
        ): SettingsScreenFlag = SettingsScreenFlag(
            database = database,
            key = SettingKey.closedHiddenLists,
            screen = screen,
            isOn = true,
            savesOn = false,
        )
    }
}
