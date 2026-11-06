package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.theme.ThemeChoice
import com.yossibank.kakeibot.core.concepts.theme.ThemeCorner
import com.yossibank.kakeibot.core.concepts.theme.ThemeDraft
import com.yossibank.kakeibot.core.concepts.theme.ThemeFont
import com.yossibank.kakeibot.core.concepts.theme.ThemeLook
import com.yossibank.kakeibot.core.concepts.theme.ThemePreset
import com.yossibank.kakeibot.core.concepts.theme.ThemeStyle
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.customThemes
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.queries.methods.style
import com.yossibank.kakeibot.store.queries.methods.themeLook
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.cornerStyle
import com.yossibank.kakeibot.store.records.settingkeys.fontStyle
import com.yossibank.kakeibot.store.records.settingkeys.textFontStyle
import com.yossibank.kakeibot.store.records.settingkeys.theme
import com.yossibank.kakeibot.store.writes.methods.deleteTheme
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.saveTheme
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class ThemeWriteTest {
    @Test
    fun usesChosenCustomTheme() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)

        val theme = database.saveTheme(mint, at = now)
        database.setSetting(SettingKey.theme, to = ThemeChoice.Custom(theme.id))
        val look = database.themeLook()
        val palette = assertNotNull(mint.palette)

        assertEquals(ThemeLook.Fixed(palette), look)

        database.close()
    }

    @Test
    fun followsDeviceByDefault() = runTest {
        val database = AppDatabase.inMemory()

        val look = database.themeLook()

        assertEquals(ThemeLook.followsDevice, look)

        database.close()
    }

    @Test
    fun savesFollowingDevice() = runTest {
        val database = AppDatabase.inMemory()

        database.setSetting(SettingKey.theme, to = ThemeChoice.Preset(ThemePreset.black))
        database.setSetting(SettingKey.theme, to = ThemeChoice.System)
        val choice = database.setting(SettingKey.theme)
        val look = database.themeLook()

        assertEquals(ThemeChoice.System, choice)
        assertEquals(ThemeLook.followsDevice, look)

        database.close()
    }

    @Test
    fun readsChosenStyle() = runTest {
        val database = AppDatabase.inMemory()

        val expected = ThemeStyle(
            corner = ThemeCorner.large,
            displayFont = ThemeFont.rounded,
            textFont = ThemeFont.mincho,
        )

        database.setSetting(SettingKey.cornerStyle, to = ThemeCorner.large)
        database.setSetting(SettingKey.fontStyle, to = ThemeFont.rounded)
        database.setSetting(SettingKey.textFontStyle, to = ThemeFont.mincho)
        val style = database.style()

        assertEquals(expected, style)

        database.close()
    }

    @Test
    fun usesStandardStyleByDefault() = runTest {
        val database = AppDatabase.inMemory()

        val style = database.style()

        assertEquals(ThemeStyle.standard, style)

        database.close()
    }

    @Test
    fun updatesTheme() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)
        val later = now.plusSeconds(60)
        val theme = database.saveTheme(mint, at = now)

        val updated = database.saveTheme(
            mint.copy(name = "夜のミント"),
            editing = theme.id,
            at = later,
        )

        val themes = database.customThemes()

        assertEquals(theme.id, updated.id)
        assertEquals(listOf("夜のミント"), themes.map { it.name })

        database.close()
    }

    @Test
    fun returnsToWhiteAfterDeletingChosenTheme() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)
        val theme = database.saveTheme(mint, at = now)
        database.setSetting(SettingKey.theme, to = ThemeChoice.Custom(theme.id))

        database.deleteTheme(theme.id)
        val choice = database.setting(SettingKey.theme)
        val themes = database.customThemes()

        assertEquals(ThemeChoice.Preset(ThemePreset.white), choice)
        assertTrue(themes.isEmpty())

        database.close()
    }

    @Test
    fun restoresDeletedChosenTheme() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)
        val theme = database.saveTheme(mint, at = now)
        database.setSetting(SettingKey.theme, to = ThemeChoice.Custom(theme.id))

        val deletion = database.deleteTheme(theme.id)
        database.restore(deletion)
        val choice = database.setting(SettingKey.theme)
        val themes = database.customThemes()

        assertEquals(ThemeChoice.Custom(theme.id), choice)
        assertEquals(listOf(theme), themes)

        database.close()
    }

    @Test
    fun keepsChoiceWhenRestoringUnchosenTheme() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)
        val theme = database.saveTheme(mint, at = now)
        database.setSetting(SettingKey.theme, to = ThemeChoice.Preset(ThemePreset.black))

        val deletion = database.deleteTheme(theme.id)
        database.setSetting(SettingKey.theme, to = ThemeChoice.Preset(ThemePreset.white))
        database.restore(deletion)
        val choice = database.setting(SettingKey.theme)
        val themes = database.customThemes()

        assertEquals(ThemeChoice.Preset(ThemePreset.white), choice)
        assertEquals(listOf(theme), themes)

        database.close()
    }

    @Test
    fun rejectsUnreadableTheme() = runTest {
        val database = AppDatabase.inMemory()
        val draft = mint.copy(text = mint.background)

        val error = assertFailsWith<DraftProblemException> {
            database.saveTheme(draft, at = Instant.now())
        }

        assertEquals(DraftProblem.unreadableColors, error.problem)

        database.close()
    }
}

private val mint = ThemeDraft(
    name = "ミント",
    background = "#12302C",
    surface = "#173A35",
    text = "#EAF4F1",
    subtext = "#8FB3A9",
    accent = "#7FD1B9",
)
