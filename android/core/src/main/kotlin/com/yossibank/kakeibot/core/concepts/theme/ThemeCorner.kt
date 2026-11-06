package com.yossibank.kakeibot.core.concepts.theme

enum class ThemeCorner(
    val rawValue: String,
    val scale: Double,
) {
    square(
        "square",
        0.0,
    ),
    small(
        "small",
        0.6,
    ),
    standard(
        "standard",
        1.0,
    ),
    large(
        "large",
        1.4,
    ),
    ;

    companion object {
        fun of(rawValue: String): ThemeCorner? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
