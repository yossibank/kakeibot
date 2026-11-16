package com.yossibank.kakeibot.store.queries.types

import java.time.Instant

data class EntryHistory(
    val count: Int,
    val firstCreatedAt: Instant?,
)
