package com.yossibank.kakeibot.core.concepts.theme

internal object ThemeHex {
    fun rgb(text: String): Int? {
        val digits = text.drop(1)

        val isHex = digits.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }

        if (!text.startsWith("#") || digits.length != 6 || !isHex) {
            return null
        }

        return digits.toInt(16)
    }

    fun text(rgb: Int): String {
        val digits = rgb.toString(16).uppercase()

        return "#" + digits.padStart(6, '0')
    }
}
