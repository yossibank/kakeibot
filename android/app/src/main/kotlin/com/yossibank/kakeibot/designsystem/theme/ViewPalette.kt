package com.yossibank.kakeibot.designsystem.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.LocalTextStyle
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.yossibank.kakeibot.core.concepts.theme.ThemeLook
import com.yossibank.kakeibot.core.concepts.theme.ThemeStyle
import com.yossibank.kakeibot.core.concepts.theme.isLight

@Composable
fun PaletteScene(
    look: ThemeLook,
    style: ThemeStyle,
    content: @Composable () -> Unit,
) {
    val view = LocalView.current
    val palette = look.palette(isDark = isSystemInDarkTheme())

    SideEffect {
        val window = (view.context as? Activity)?.window ?: return@SideEffect
        val controller = WindowCompat.getInsetsController(window, view)

        controller.isAppearanceLightStatusBars = palette.isLight
        controller.isAppearanceLightNavigationBars = palette.isLight
    }

    CompositionLocalProvider(
        LocalPalette provides palette,
        LocalThemeStyle provides style,
    ) {
        CompositionLocalProvider(
            LocalContentColor provides Palette.text,
            LocalTextStyle provides bodyFont,
            content = content,
        )
    }
}
