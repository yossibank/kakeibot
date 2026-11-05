package com.yossibank.kakeibot.core.concepts.theme

enum class ThemeRowSpacing(
    val rawValue: String,
    val padding: Double,
    val minHeight: Double,
) {
    compact(
        "compact",
        4.0,
        40.0,
    ),
    standard(
        "standard",
        8.0,
        48.0,
    ),
    relaxed(
        "relaxed",
        12.0,
        56.0,
    ),
    ;

    companion object {
        fun of(rawValue: String): ThemeRowSpacing? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
