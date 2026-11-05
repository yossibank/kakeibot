package com.yossibank.kakeibot.core.shared

class DraftProblemException(
    val problem: DraftProblem,
) : Exception(problem.name)
