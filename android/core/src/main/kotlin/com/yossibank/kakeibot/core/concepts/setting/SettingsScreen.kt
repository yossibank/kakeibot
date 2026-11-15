package com.yossibank.kakeibot.core.concepts.setting

enum class SettingsScreen(
    val rawValue: String,
) {
    categories("categories"),
    wallets("wallets"),
    templates("templates"),
    recurrings("recurrings"),
    stamps("stamps"),
    rewards("rewards"),
    budgets("budgets"),
    themes("themes"),
    homeSections("homeSections"),
    themeText("themeText"),
    themeLook("themeLook"),
    reminder("reminder"),
    monthStartDay("monthStartDay"),
    launchScreen("launchScreen"),
    sync("sync"),
    backup("backup"),
    appIcons("appIcons"),
    widgetGuide("widgetGuide"),
    ;

    companion object {
        fun of(rawValue: String): SettingsScreen? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
