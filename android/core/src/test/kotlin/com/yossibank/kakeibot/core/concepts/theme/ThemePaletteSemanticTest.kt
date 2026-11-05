package com.yossibank.kakeibot.core.concepts.theme

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@RunWith(Enclosed::class)
class ThemePaletteSemanticTest {
    @RunWith(Parameterized::class)
    class MakesReadableColor(
        private val fixture: SemanticCase,
    ) {
        @Serializable
        data class SemanticCase(
            val summary: String,
            val background: String,
            val semantic: String,
            val color: String?,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun makesReadableColor() {
            val background = assertNotNull(fixture.background.drop(1).toIntOrNull(16))
            val palette = palette(background)
            val semantic = assertNotNull(ThemePalette.Semantic.of(fixture.semantic))
            val color = palette.color(semantic)
            val base = if (palette.isLight) semantic.light else semantic.dark
            val expected = fixture.color

            if (expected != null) {
                assertEquals(expected.drop(1).toIntOrNull(16), color)
            } else {
                val contrast = ThemePalette.contrast(color, background)

                assertNotEquals(base, color)
                assertTrue(contrast >= 3)
            }
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<SemanticCase> = CoreFixture.cases("theme/theme-palette-semantic.json", SemanticCase.serializer())
        }
    }

    class Presets {
        @Test
        fun keepsPresetColors() {
            for (preset in ThemePreset.entries) {
                val palette = preset.palette

                for (semantic in ThemePalette.Semantic.entries) {
                    val base = if (palette.isLight) semantic.light else semantic.dark

                    assertEquals(base, palette.color(semantic), "${preset.rawValue} ${semantic.rawValue}")
                }
            }
        }
    }
}

private fun palette(background: Int): ThemePalette =
    ThemePalette.night.copy(
        backgroundTop = background,
        backgroundBottom = background,
        panel = background,
        cardTop = background,
        cardBottom = background,
    )
