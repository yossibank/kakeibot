package com.yossibank.kakeibot.core.concepts.review

import kotlinx.serialization.Serializable

@Serializable
enum class ReviewKind(
    val rawValue: String,
) {
    expense("expense"),
    income("income"),
    balance("balance"),
    ;

    companion object {
        fun of(rawValue: String): ReviewKind? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
