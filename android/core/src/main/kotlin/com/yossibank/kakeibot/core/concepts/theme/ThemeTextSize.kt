package com.yossibank.kakeibot.core.concepts.theme

enum class ThemeTextSize(
    val rawValue: String,
    val scale: Double,
) {
    small(
        "small",
        0.9,
    ),
    standard(
        "standard",
        1.0,
    ),
    large(
        "large",
        1.15,
    ),
    ;

    companion object {
        fun of(rawValue: String): ThemeTextSize? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
