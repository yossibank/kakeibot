package com.yossibank.kakeibot.core.concepts.theme

import kotlinx.serialization.Serializable

data class ThemePalette(
    val backgroundTop: Int,
    val backgroundBottom: Int,
    val panel: Int,
    val cardTop: Int,
    val cardBottom: Int,
    val line: Int,
    val accent: Int,
    val accentDeep: Int,
    val accentStrong: Int,
    val text: Int,
    val subtext: Int,
    val hint: Int,
) {
    @Serializable
    enum class Role(
        val rawValue: String,
    ) {
        backgroundTop("backgroundTop"),
        backgroundBottom("backgroundBottom"),
        panel("panel"),
        cardTop("cardTop"),
        cardBottom("cardBottom"),
        line("line"),
        accent("accent"),
        accentDeep("accentDeep"),
        accentStrong("accentStrong"),
        text("text"),
        subtext("subtext"),
        hint("hint"),
        ;

        companion object {
            fun of(rawValue: String): Role? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }

    enum class Semantic(
        val rawValue: String,
        val light: Int,
        val dark: Int,
    ) {
        rose(
            "rose",
            0xB04A4A,
            0xE3A3A3,
        ),
        amber(
            "amber",
            0xA8581A,
            0xE89B57,
        ),
        holiday(
            "holiday",
            0xC0392B,
            0xEE8A84,
        ),
        saturday(
            "saturday",
            0x2D63B5,
            0x8DB0EA,
        ),
        ;

        companion object {
            fun of(rawValue: String): Semantic? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }

    operator fun get(role: Role): Int =
        when (role) {
            Role.backgroundTop -> backgroundTop
            Role.backgroundBottom -> backgroundBottom
            Role.panel -> panel
            Role.cardTop -> cardTop
            Role.cardBottom -> cardBottom
            Role.line -> line
            Role.accent -> accent
            Role.accentDeep -> accentDeep
            Role.accentStrong -> accentStrong
            Role.text -> text
            Role.subtext -> subtext
            Role.hint -> hint
        }

    companion object {
        val night = ThemePalette(
            backgroundTop = 0x16223D,
            backgroundBottom = 0x080C16,
            panel = 0x0E1628,
            cardTop = 0x141C2F,
            cardBottom = 0x090D18,
            line = 0x26314A,
            accent = 0xCDAA6B,
            accentDeep = 0x8F6C38,
            accentStrong = 0xF4E6C1,
            text = 0xEDE6D6,
            subtext = 0x8C97AE,
            hint = 0x7E89A0,
        )
    }
}
