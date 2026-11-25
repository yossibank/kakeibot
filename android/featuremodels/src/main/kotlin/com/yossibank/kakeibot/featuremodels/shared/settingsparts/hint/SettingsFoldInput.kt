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

class SettingsFoldInput internal constructor(
    private val key: SettingKey<Set<SettingsScreen>>,
    private val screen: SettingsScreen,
) {
    var isClosed: Boolean? by mutableStateOf(null)
        private set

    internal suspend fun load(from: AppDatabase) {
        val screens = read(from) ?: emptySet()

        isClosed = screen in screens
    }

    internal suspend fun save(
        isClosed: Boolean,
        to: AppDatabase,
    ) {
        this.isClosed = isClosed

        val screens = read(to)?.toMutableSet() ?: mutableSetOf()

        if (isClosed) {
            screens.add(screen)
        } else {
            screens.remove(screen)
        }

        ModelTask.quiet {
            to.setSetting(
                key = key,
                to = screens,
            )
        }
    }

    private suspend fun read(from: AppDatabase): Set<SettingsScreen>? =
        ModelTask.quiet { from.setting(key) }

    companion object {
        internal fun hint(screen: SettingsScreen): SettingsFoldInput = SettingsFoldInput(
            key = SettingKey.closedHints,
            screen = screen,
        )

        internal fun hiddenList(screen: SettingsScreen): SettingsFoldInput = SettingsFoldInput(
            key = SettingKey.closedHiddenLists,
            screen = screen,
        )
    }
}
