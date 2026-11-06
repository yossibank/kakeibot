package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.theme.Theme
import com.yossibank.kakeibot.core.concepts.theme.ThemeChoice
import com.yossibank.kakeibot.core.concepts.theme.ThemeLook
import com.yossibank.kakeibot.core.concepts.theme.ThemeStyle
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.ThemeRecord
import com.yossibank.kakeibot.store.records.rows.theme
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.backdrop
import com.yossibank.kakeibot.store.records.settingkeys.cornerStyle
import com.yossibank.kakeibot.store.records.settingkeys.decorations
import com.yossibank.kakeibot.store.records.settingkeys.fontStyle
import com.yossibank.kakeibot.store.records.settingkeys.haptics
import com.yossibank.kakeibot.store.records.settingkeys.rowSpacing
import com.yossibank.kakeibot.store.records.settingkeys.stampShape
import com.yossibank.kakeibot.store.records.settingkeys.tabTitles
import com.yossibank.kakeibot.store.records.settingkeys.textFontStyle
import com.yossibank.kakeibot.store.records.settingkeys.textSize
import com.yossibank.kakeibot.store.records.settingkeys.theme
import com.yossibank.kakeibot.store.records.values.databaseValue
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged

fun AppDatabase.customThemeUpdates(): Flow<List<Theme>> = observation("theme") {
    fetchCustomThemes()
}

suspend fun AppDatabase.customThemes(): List<Theme> = read {
    fetchCustomThemes()
}

fun AppDatabase.themeLookUpdates(): Flow<ThemeLook> = observation(
    "setting",
    "theme",
) {
    fetchThemeLook()
}.distinctUntilChanged()

suspend fun AppDatabase.themeLook(): ThemeLook = read {
    fetchThemeLook()
}

fun AppDatabase.styleUpdates(): Flow<ThemeStyle> = observation("setting") {
    fetchStyle()
}.distinctUntilChanged()

suspend fun AppDatabase.style(): ThemeStyle = read {
    fetchStyle()
}

private suspend fun AppDatabase.fetchCustomThemes(): List<Theme> = themeDao()
    .custom()
    .map { it.decoded(ThemeRecord::theme) }

private suspend fun AppDatabase.fetchThemeLook(): ThemeLook = when (val choice = fetchSetting(SettingKey.theme)) {
    ThemeChoice.System -> ThemeLook.followsDevice

    is ThemeChoice.Preset -> ThemeLook.Fixed(choice.preset.palette)

    is ThemeChoice.Custom -> {
        val theme = themeDao().find(choice.id.databaseValue)?.decoded(ThemeRecord::theme)

        theme?.let { ThemeLook.Fixed(it.palette) } ?: ThemeLook.followsDevice
    }
}

private suspend fun AppDatabase.fetchStyle(): ThemeStyle = ThemeStyle(
    corner = fetchSetting(SettingKey.cornerStyle),
    displayFont = fetchSetting(SettingKey.fontStyle),
    textFont = fetchSetting(SettingKey.textFontStyle),
    textSize = fetchSetting(SettingKey.textSize),
    rowSpacing = fetchSetting(SettingKey.rowSpacing),
    stampShape = fetchSetting(SettingKey.stampShape),
    showsTabTitles = fetchSetting(SettingKey.tabTitles),
    backdrop = fetchSetting(SettingKey.backdrop),
    haptics = fetchSetting(SettingKey.haptics),
    decorations = fetchSetting(SettingKey.decorations),
)
