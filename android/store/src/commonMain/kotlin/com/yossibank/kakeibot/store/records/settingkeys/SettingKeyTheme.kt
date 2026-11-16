package com.yossibank.kakeibot.store.records.settingkeys

import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.core.concepts.theme.ThemeBackdrop
import com.yossibank.kakeibot.core.concepts.theme.ThemeChoice
import com.yossibank.kakeibot.core.concepts.theme.ThemeCorner
import com.yossibank.kakeibot.core.concepts.theme.ThemeFont
import com.yossibank.kakeibot.core.concepts.theme.ThemeRowSpacing
import com.yossibank.kakeibot.core.concepts.theme.ThemeStampShape
import com.yossibank.kakeibot.core.concepts.theme.ThemeTextSize

val SettingKey.Companion.theme: SettingKey<ThemeChoice>
    get() = of(
        key = Setting.Key.themeId,
        default = ThemeChoice.System,
        decode = { ThemeChoice.parse(it) },
        encode = { it.text },
    )

val SettingKey.Companion.cornerStyle: SettingKey<ThemeCorner>
    get() = raw(
        key = Setting.Key.cornerStyle,
        default = ThemeCorner.standard,
        parse = ThemeCorner::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.fontStyle: SettingKey<ThemeFont>
    get() = raw(
        key = Setting.Key.fontStyle,
        default = ThemeFont.mincho,
        parse = ThemeFont::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.textFontStyle: SettingKey<ThemeFont>
    get() = raw(
        key = Setting.Key.textFontStyle,
        default = ThemeFont.gothic,
        parse = ThemeFont::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.textSize: SettingKey<ThemeTextSize>
    get() = raw(
        key = Setting.Key.textSize,
        default = ThemeTextSize.standard,
        parse = ThemeTextSize::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.rowSpacing: SettingKey<ThemeRowSpacing>
    get() = raw(
        key = Setting.Key.rowSpacing,
        default = ThemeRowSpacing.standard,
        parse = ThemeRowSpacing::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.stampShape: SettingKey<ThemeStampShape>
    get() = raw(
        key = Setting.Key.stampShape,
        default = ThemeStampShape.circle,
        parse = ThemeStampShape::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.backdrop: SettingKey<ThemeBackdrop>
    get() = of(
        key = Setting.Key.backdrop,
        default = ThemeBackdrop.plain,
        decode = { text ->
            ThemeBackdrop.of(text) ?: if (text == "washi") ThemeBackdrop.ruled else null
        },
        encode = { it.rawValue },
    )
