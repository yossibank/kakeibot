package com.yossibank.kakeibot.core.concepts.theme

enum class ThemeFont(
    val rawValue: String,
) {
    mincho("mincho"),
    gothic("gothic"),
    rounded("rounded"),
    handwriting("handwriting"),
    dot("dot"),
    pop("pop"),
    ;

    companion object {
        fun of(rawValue: String): ThemeFont? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
