package com.yossibank.kakeibot.core.shared

import com.yossibank.kakeibot.core.concepts.icon.Icon
import java.time.Instant

interface IconBackedDraft<Value : Any> {
    fun newIcon(at: Instant): Icon

    fun newValue(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): Value

    fun applied(
        to: Icon,
        at: Instant,
    ): Icon

    fun applied(
        to: Value,
        at: Instant,
    ): Value
}
