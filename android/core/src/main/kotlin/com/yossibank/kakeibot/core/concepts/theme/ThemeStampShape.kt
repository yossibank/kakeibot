package com.yossibank.kakeibot.core.concepts.theme

enum class ThemeStampShape(
    val rawValue: String,
) {
    circle("circle"),
    rounded("rounded"),
    seal("seal"),
    ;

    companion object {
        fun of(rawValue: String): ThemeStampShape? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
