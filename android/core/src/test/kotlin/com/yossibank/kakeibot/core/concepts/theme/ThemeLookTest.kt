package com.yossibank.kakeibot.core.concepts.theme

import org.junit.Test
import kotlin.test.assertEquals

class ThemeLookTest {
    @Test
    fun followsDeviceStyle() {
        val look = ThemeLook.followsDevice

        val light = look.palette(isDark = false)
        val dark = look.palette(isDark = true)

        assertEquals(ThemePreset.white.palette, light)
        assertEquals(ThemePreset.black.palette, dark)
    }

    @Test
    fun keepsFixedPalette() {
        val look = ThemeLook.Fixed(ThemePreset.navy.palette)
        val dark = look.palette(isDark = true)

        assertEquals(ThemePreset.navy.palette, dark)
    }

    @Test
    fun readsSystemChoice() {
        val choice = ThemeChoice.parse("system")

        assertEquals(ThemeChoice.System, choice)
        assertEquals("system", choice?.text)
    }
}
