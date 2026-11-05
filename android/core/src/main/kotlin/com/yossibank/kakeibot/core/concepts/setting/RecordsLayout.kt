package com.yossibank.kakeibot.core.concepts.setting

enum class RecordsLayout(
    val rawValue: String,
) {
    calendar("calendar"),
    list("list"),
    ;

    companion object {
        fun of(rawValue: String): RecordsLayout? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
