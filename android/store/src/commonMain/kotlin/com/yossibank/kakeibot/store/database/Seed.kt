package com.yossibank.kakeibot.store.database

import com.yossibank.kakeibot.core.concepts.icon.Icon

internal data class Seed(
    val name: String,
    val glyph: Icon.Glyph,
    val color: String,
)

internal val feeSeed = Seed("手数料", Icon.Glyph.coin, "#A68A64")

internal val transferSeed = Seed("振替", Icon.Glyph.banknote, "#7A8B99")
