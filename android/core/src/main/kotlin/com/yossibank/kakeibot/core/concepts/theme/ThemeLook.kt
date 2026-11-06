package com.yossibank.kakeibot.core.concepts.theme

sealed interface ThemeLook {
    fun palette(isDark: Boolean): ThemePalette

    data class Fixed(
        val palette: ThemePalette,
    ) : ThemeLook {
        override fun palette(isDark: Boolean): ThemePalette = palette
    }

    data class System(
        val light: ThemePalette,
        val dark: ThemePalette,
    ) : ThemeLook {
        override fun palette(isDark: Boolean): ThemePalette = if (isDark) dark else light
    }

    companion object {
        val followsDevice: ThemeLook = System(
            light = ThemePreset.white.palette,
            dark = ThemePreset.black.palette,
        )
    }
}
