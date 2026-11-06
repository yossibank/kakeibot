package com.yossibank.kakeibot.core.concepts.theme

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.math.roundToLong
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@RunWith(Enclosed::class)
class ThemePaletteContrastTest {
    @RunWith(Parameterized::class)
    class MeasuresContrast(
        private val fixture: ContrastCase,
    ) {
        @Serializable
        data class ContrastCase(
            val summary: String,
            val first: String,
            val second: String,
            val ratio: Double,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun measuresContrast() {
            val first = rgb(fixture.first)
            val second = rgb(fixture.second)
            val ratio = ThemePalette.contrast(first, second)
            val roundedRatio = (ratio * 100).roundToLong() / 100.0

            assertEquals(fixture.ratio, roundedRatio)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<ContrastCase> = CoreFixture.cases("theme/theme-palette-contrast.json", ContrastCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class FindsUnreadableRoles(
        private val fixture: ReadableCase,
    ) {
        @Serializable
        data class ReadableCase(
            val summary: String,
            val theme: Map<String, String>,
            val unreadable: List<ThemePalette.Role>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsUnreadableRoles() {
            val theme = theme(fixture.theme)

            assertEquals(fixture.unreadable, theme.unreadableRoles)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<ReadableCase> = CoreFixture.cases("theme/theme-palette-readable.json", ReadableCase.serializer())
        }
    }

    class Presets {
        @Test
        fun keepsPresetsReadable() {
            for (preset in ThemePreset.entries) {
                assertTrue(preset.palette.unreadableRoles.isEmpty(), preset.rawValue)
            }
        }

        @Test
        fun keepsPresetHintsReadableAsBody() {
            val surfaces = listOf(
                ThemePalette.Role.backgroundTop,
                ThemePalette.Role.backgroundBottom,
                ThemePalette.Role.panel,
                ThemePalette.Role.cardTop,
                ThemePalette.Role.cardBottom,
            )

            for (preset in ThemePreset.entries) {
                val palette = preset.palette
                val lowest = surfaces.minOf { ThemePalette.contrast(palette.hint, palette[it]) }

                assertTrue(lowest >= 4.5, preset.rawValue)
            }
        }

        @Test
        fun tellsLightBackground() {
            val light = ThemePreset.entries.filter { it.palette.isLight }

            assertEquals(
                listOf(
                    ThemePreset.white,
                    ThemePreset.ivory,
                    ThemePreset.sky,
                    ThemePreset.sage,
                    ThemePreset.rose,
                    ThemePreset.gold,
                ),
                light,
            )
        }
    }
}

private fun rgb(hex: String): Int = hex.drop(1).toIntOrNull(16) ?: 0

private fun theme(colors: Map<String, String>): ThemePalette {
    fun color(role: ThemePalette.Role): Int = rgb(colors[role.rawValue] ?: "")

    return ThemePalette(
        backgroundTop = color(ThemePalette.Role.backgroundTop),
        backgroundBottom = color(ThemePalette.Role.backgroundBottom),
        panel = color(ThemePalette.Role.panel),
        cardTop = color(ThemePalette.Role.cardTop),
        cardBottom = color(ThemePalette.Role.cardBottom),
        line = color(ThemePalette.Role.line),
        accent = color(ThemePalette.Role.accent),
        accentDeep = color(ThemePalette.Role.accentDeep),
        accentStrong = color(ThemePalette.Role.accentStrong),
        text = color(ThemePalette.Role.text),
        subtext = color(ThemePalette.Role.subtext),
        hint = color(ThemePalette.Role.hint),
    )
}
