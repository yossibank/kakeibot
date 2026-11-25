package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

enum class RecurringPanel(
    val title: String,
) {
    Amount("金額"),
    Start("始まり"),
    End("終わり"),
    Holiday("休日なら"),
    Closing("金額の決め方"),
    Fee("手数料"),
    Count("回数"),
    Remind("前に知らせる"),
}
