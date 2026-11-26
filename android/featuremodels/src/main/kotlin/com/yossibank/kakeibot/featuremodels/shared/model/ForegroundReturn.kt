package com.yossibank.kakeibot.featuremodels.shared.model

class ForegroundReturn {
    private var wasBackground = false

    enum class Phase {
        Active,
        Inactive,
        Background,
    }

    fun receive(phase: Phase): Boolean = when (phase) {
        Phase.Background -> {
            wasBackground = true

            false
        }

        Phase.Active -> {
            val isReturn = wasBackground
            wasBackground = false

            isReturn
        }

        Phase.Inactive -> {
            false
        }
    }
}
