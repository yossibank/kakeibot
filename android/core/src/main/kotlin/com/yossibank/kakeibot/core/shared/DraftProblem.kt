package com.yossibank.kakeibot.core.shared

import kotlinx.serialization.Serializable

@Serializable
enum class DraftProblem {
    emptyName,
    emptyAmount,
    emptyMark,
    textTooLong,
    invalidColor,
    nameTooLong,
    unreadableColors,
    kindLocked,
    valuedKindLocked,
}
