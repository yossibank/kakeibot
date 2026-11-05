package com.yossibank.kakeibot.core.concepts.theme

import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals

@RunWith(Enclosed::class)
class ThemeDraftTest {
    @RunWith(Parameterized::class)
    class MakesPaletteFromBaseColors(
        private val fixture: BaseCase,
    ) {
        @Serializable
        data class BaseCase(
            val summary: String,
            val background: String,
            val surface: String,
            val text: String,
            val subtext: String,
            val accent: String,
            val palette: Map<String, String>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun makesPaletteFromBaseColors() {
            val draft = ThemeDraft(
                name = "テーマ",
                background = fixture.background,
                surface = fixture.surface,
                text = fixture.text,
                subtext = fixture.subtext,
                accent = fixture.accent,
            )

            val palette = draft.palette?.let(::colors)

            assertEquals(fixture.palette, palette)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<BaseCase> = CoreFixture.cases("theme/theme-palette-base.json", BaseCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class FindsProblems(
        private val fixture: DraftCase,
    ) {
        @Serializable
        data class DraftCase(
            val summary: String,
            val name: String,
            val background: String,
            val surface: String,
            val text: String,
            val subtext: String,
            val accent: String,
            val problems: List<DraftProblem>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsProblems() {
            val draft = ThemeDraft(
                name = fixture.name,
                background = fixture.background,
                surface = fixture.surface,
                text = fixture.text,
                subtext = fixture.subtext,
                accent = fixture.accent,
            )

            assertEquals(fixture.problems, draft.problems)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<DraftCase> = CoreFixture.cases("theme/theme-draft.json", DraftCase.serializer())
        }
    }

    class Presets {
        @Test
        fun keepsPresetColorsAsDraft() {
            for (preset in ThemePreset.entries) {
                val draft = ThemeDraft(
                    name = preset.title,
                    palette = preset.palette,
                )

                assertEquals(preset.palette.backgroundTop, draft.palette?.backgroundTop, preset.rawValue)
                assertEquals(preset.palette.accent, draft.palette?.accent, preset.rawValue)
            }
        }
    }
}

private fun colors(palette: ThemePalette): Map<String, String> =
    ThemePalette.Role.entries.associate { role ->
        val digits = palette[role].toString(16).uppercase()
        val hex = "#" + digits.padStart(6, '0')

        role.rawValue to hex
    }
