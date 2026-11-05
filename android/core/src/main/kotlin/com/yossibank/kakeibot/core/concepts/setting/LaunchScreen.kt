package com.yossibank.kakeibot.core.concepts.setting

enum class LaunchScreen(
    val rawValue: String,
) {
    home("home"),
    records("records"),
    review("review"),
    assets("assets"),
    entry("entry"),
    ;

    companion object {
        fun of(rawValue: String): LaunchScreen? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
