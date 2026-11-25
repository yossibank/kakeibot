package com.yossibank.kakeibot.featuremodels.shared.model

import android.content.res.Resources

object DeviceName {
    private const val TABLET_WIDTH = 600

    val current: String
        get() = name(ofWidth = Resources.getSystem()?.configuration?.smallestScreenWidthDp ?: 0)

    fun name(ofWidth: Int): String = if (ofWidth >= TABLET_WIDTH) "タブレット" else "スマホ"
}
