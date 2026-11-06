package com.yossibank.kakeibot.core.concepts.setting

enum class HomeSection(
    val rawValue: String,
) {
    customize("customize"),
    budget("budget"),
    templates("templates"),
    recent("recent"),
    bills("bills"),
    stamps("stamps"),
    ;

    val id: HomeSection
        get() = this

    companion object {
        val standard: List<HomeSection> = listOf(
            customize,
            budget,
            templates,
            recent,
        )

        fun of(rawValue: String): HomeSection? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
