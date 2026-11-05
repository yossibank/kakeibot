package com.yossibank.kakeibot.core.concepts.theme

enum class ThemeBackdrop(
    val rawValue: String,
) {
    plain("plain"),
    ruled("ruled"),
    grid("grid"),
    ;

    companion object {
        fun of(rawValue: String): ThemeBackdrop? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
