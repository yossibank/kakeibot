package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.theme.Theme
import com.yossibank.kakeibot.core.concepts.theme.ThemeChoice
import com.yossibank.kakeibot.core.concepts.theme.ThemeDraft
import com.yossibank.kakeibot.core.concepts.theme.ThemePreset
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.queries.methods.fetchSetting
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.ThemeRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.theme
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.theme
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

enum class ThemeWriteError {
    themeNotFound,
}

class ThemeWriteException(
    val error: ThemeWriteError,
) : Exception(error.name)

suspend fun AppDatabase.saveTheme(
    draft: ThemeDraft,
    editing: Identifier<Theme>? = null,
    at: Instant,
): Theme = write {
    if (editing == null) {
        val theme = draft.newTheme(at)

        themeDao().insert(theme.record())

        return@write theme
    }

    val theme = findTheme(editing) ?: throw ThemeWriteException(ThemeWriteError.themeNotFound)

    val updated = draft.applied(
        to = theme,
        at = at,
    )

    themeDao().update(updated.record())

    updated
}

suspend fun AppDatabase.deleteTheme(id: Identifier<Theme>): Deletion = write {
    val theme = findTheme(id) ?: throw ThemeWriteException(ThemeWriteError.themeNotFound)

    themeDao().delete(id.databaseValue)

    val choice = fetchSetting(SettingKey.theme)

    if (choice != ThemeChoice.Custom(id)) {
        return@write Deletion(themes = listOf(theme))
    }

    storeSetting(
        key = SettingKey.theme,
        to = ThemeChoice.Preset(ThemePreset.white),
    )

    Deletion(
        themes = listOf(theme),
        themeChoice = choice,
    )
}

private suspend fun AppDatabase.findTheme(id: Identifier<Theme>): Theme? =
    themeDao().find(id.databaseValue)?.decoded(ThemeRecord::theme)
