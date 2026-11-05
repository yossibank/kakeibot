package com.yossibank.kakeibot.core.concepts.theme

import com.yossibank.kakeibot.core.shared.Identifier

sealed interface ThemeChoice {
    val text: String

    data object System : ThemeChoice {
        override val text: String
            get() = systemText
    }

    data class Preset(
        val preset: ThemePreset,
    ) : ThemeChoice {
        override val text: String
            get() = preset.rawValue
    }

    data class Custom(
        val id: Identifier<Theme>,
    ) : ThemeChoice {
        override val text: String
            get() = id.toString()
    }

    companion object {
        private const val systemText = "system"

        fun parse(text: String): ThemeChoice? {
            if (text == systemText) {
                return System
            }

            val found = ThemePreset.of(text)

            if (found != null) {
                return Preset(found)
            }

            val id = Identifier.parse<Theme>(text) ?: return null

            return Custom(id)
        }
    }
}
