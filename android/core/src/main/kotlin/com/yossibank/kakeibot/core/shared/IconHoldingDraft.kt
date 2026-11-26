package com.yossibank.kakeibot.core.shared

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import java.time.Instant

interface IconHoldingDraft<Value : Any> : IconBackedDraft<Value> {
    val icon: IconDraft

    val problems: List<DraftProblem>

    override fun newIcon(at: Instant): Icon {
        validateProblems()
        return icon.newIcon(at)
    }

    override fun applied(
        to: Icon,
        at: Instant,
    ): Icon {
        validateProblems()

        return icon.applied(
            to = to,
            at = at,
        )
    }

    fun validateProblems() {
        val problem = problems.firstOrNull() ?: return
        throw DraftProblemException(problem)
    }
}
