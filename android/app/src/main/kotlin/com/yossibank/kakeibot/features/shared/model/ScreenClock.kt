package com.yossibank.kakeibot.features.shared.model

import java.time.Instant

class ScreenClock(
    private val current: () -> Instant,
) {
    val now: Instant
        get() = current()

    companion object {
        val system = ScreenClock { Instant.now() }

        fun fixed(instant: Instant) = ScreenClock { instant }
    }
}
