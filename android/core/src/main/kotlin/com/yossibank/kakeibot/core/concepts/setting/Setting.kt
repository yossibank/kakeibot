package com.yossibank.kakeibot.core.concepts.setting

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Setting(
    val key: Key,
    val value: String,
) {
    val id: Key
        get() = key

    @Serializable
    enum class Key(
        val rawValue: String,
    ) {
        @SerialName("month_start_day")
        monthStartDay("month_start_day"),
        @SerialName("month_start_shift")
        monthStartShift("month_start_shift"),
        @SerialName("budget_carryover_from")
        budgetCarryoverFrom("budget_carryover_from"),
        @SerialName("week_start")
        weekStart("week_start"),
        @SerialName("reminder_time")
        reminderTime("reminder_time"),
        @SerialName("theme_id")
        themeId("theme_id"),
        @SerialName("corner_style")
        cornerStyle("corner_style"),
        @SerialName("font_style")
        fontStyle("font_style"),
        @SerialName("text_font_style")
        textFontStyle("text_font_style"),
        @SerialName("text_size")
        textSize("text_size"),
        @SerialName("row_spacing")
        rowSpacing("row_spacing"),
        @SerialName("stamp_shape")
        stampShape("stamp_shape"),
        @SerialName("tab_titles")
        tabTitles("tab_titles"),
        @SerialName("backdrop")
        backdrop("backdrop"),
        @SerialName("haptics")
        haptics("haptics"),
        @SerialName("decorations")
        decorations("decorations"),
        @SerialName("onboarding_completed")
        onboardingCompleted("onboarding_completed"),
        @SerialName("setup_card_closed")
        setupCardClosed("setup_card_closed"),
        @SerialName("entry_opened")
        entryOpened("entry_opened"),
        @SerialName("settings_opened")
        settingsOpened("settings_opened"),
        @SerialName("launch_screen")
        launchScreen("launch_screen"),
        @SerialName("entry_starts_with_amount")
        entryStartsWithAmount("entry_starts_with_amount"),
        @SerialName("template_order")
        templateOrder("template_order"),
        @SerialName("home_sections")
        homeSections("home_sections"),
        @SerialName("home_hidden_sections")
        homeHiddenSections("home_hidden_sections"),
        @SerialName("categories_by_use")
        categoriesByUse("categories_by_use"),
        @SerialName("records_layout")
        recordsLayout("records_layout"),
        @SerialName("review_scale")
        reviewScale("review_scale"),
        @SerialName("review_kind")
        reviewKind("review_kind"),
        @SerialName("closed_hints")
        closedHints("closed_hints"),
        @SerialName("closed_hidden_lists")
        closedHiddenLists("closed_hidden_lists"),
        @SerialName("recent_searches")
        recentSearches("recent_searches"),
        @SerialName("receipt_saved_count")
        receiptSavedCount("receipt_saved_count"),
        @SerialName("receipt_guide_hidden")
        receiptGuideHidden("receipt_guide_hidden"),
        @SerialName("widget_entry")
        widgetEntry("widget_entry"),
        @SerialName("fee_category_id")
        feeCategoryId("fee_category_id"),
        @SerialName("transfer_out_category_id")
        transferOutCategoryId("transfer_out_category_id"),
        @SerialName("transfer_in_category_id")
        transferInCategoryId("transfer_in_category_id"),
        @SerialName("backup_exported_at")
        backupExportedAt("backup_exported_at"),
        @SerialName("review_requested_version")
        reviewRequestedVersion("review_requested_version"),
        @SerialName("whats_new_seen_version")
        whatsNewSeenVersion("whats_new_seen_version"),
        ;

        companion object {
            fun of(rawValue: String): Key? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }
}
