package com.yossibank.kakeibot.core.concepts.setting

enum class TemplateOrder(
    val rawValue: String,
) {
    manual("manual"),
    frequent("frequent"),
    category("category"),
    amount("amount"),
    byName("name"),
    ;

    val id: TemplateOrder
        get() = this

    companion object {
        const val frequentDays = 90

        fun of(rawValue: String): TemplateOrder? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
