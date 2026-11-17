package com.yossibank.kakeibot.designsystem.components.icon

import androidx.annotation.DrawableRes
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.icon.Icon

@get:DrawableRes
val Icon.Glyph.symbol: Int
    get() = when (this) {
        Icon.Glyph.food -> R.drawable.ic_glyph_food
        Icon.Glyph.daily -> R.drawable.ic_glyph_daily
        Icon.Glyph.transit -> R.drawable.ic_glyph_transit
        Icon.Glyph.social -> R.drawable.ic_glyph_social
        Icon.Glyph.hobby -> R.drawable.ic_glyph_hobby
        Icon.Glyph.clothes -> R.drawable.ic_glyph_clothes
        Icon.Glyph.beauty -> R.drawable.ic_glyph_beauty
        Icon.Glyph.medical -> R.drawable.ic_glyph_medical
        Icon.Glyph.home -> R.drawable.ic_glyph_home
        Icon.Glyph.phone -> R.drawable.ic_glyph_phone
        Icon.Glyph.utility -> R.drawable.ic_glyph_utility
        Icon.Glyph.salary -> R.drawable.ic_glyph_salary
        Icon.Glyph.bonus -> R.drawable.ic_glyph_bonus
        Icon.Glyph.other -> R.drawable.ic_glyph_other
        Icon.Glyph.cash -> R.drawable.ic_glyph_cash
        Icon.Glyph.bank -> R.drawable.ic_glyph_bank
        Icon.Glyph.coin -> R.drawable.ic_glyph_coin
        Icon.Glyph.banknote -> R.drawable.ic_glyph_banknote
        else -> R.drawable.ic_glyph_fallback
    }
