package com.yossibank.kakeibot.store.records.settingkeys

import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.core.concepts.setting.HomeSection
import com.yossibank.kakeibot.core.concepts.setting.RecordsLayout
import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.concepts.setting.TemplateOrder

val SettingKey.Companion.templateOrder: SettingKey<TemplateOrder>
    get() = raw(
        key = Setting.Key.templateOrder,
        default = TemplateOrder.manual,
        parse = TemplateOrder::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.homeSections: SettingKey<List<HomeSection>>
    get() = of(
        key = Setting.Key.homeSections,
        default = HomeSection.standard,
        decode = { text ->
            text.split(",").mapNotNull { HomeSection.of(it) }
        },
        encode = { sections ->
            sections.joinToString(",") { it.rawValue }
        },
    )

val SettingKey.Companion.homeHiddenSections: SettingKey<Set<HomeSection>>
    get() = of(
        key = Setting.Key.homeHiddenSections,
        default = emptySet(),
        decode = { text ->
            text.split(",")
                .mapNotNull { HomeSection.of(it) }
                .toSet()
        },
        encode = { sections ->
            val names = sections.map { it.rawValue }.sorted()

            if (names.isEmpty()) null else names.joinToString(",")
        },
    )

val SettingKey.Companion.recordsLayout: SettingKey<RecordsLayout>
    get() = raw(
        key = Setting.Key.recordsLayout,
        default = RecordsLayout.calendar,
        parse = RecordsLayout::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.reviewScale: SettingKey<ReviewPeriod.Scale>
    get() = raw(
        key = Setting.Key.reviewScale,
        default = ReviewPeriod.Scale.month,
        parse = ReviewPeriod.Scale::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.reviewKind: SettingKey<ReviewKind>
    get() = raw(
        key = Setting.Key.reviewKind,
        default = ReviewKind.expense,
        parse = ReviewKind::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.closedHints: SettingKey<Set<SettingsScreen>>
    get() = screens(Setting.Key.closedHints)

val SettingKey.Companion.closedHiddenLists: SettingKey<Set<SettingsScreen>>
    get() = screens(Setting.Key.closedHiddenLists)

val SettingKey.Companion.recentSearches: SettingKey<List<String>>
    get() = of(
        key = Setting.Key.recentSearches,
        default = emptyList(),
        decode = { text ->
            text.split("\n").filter { it.isNotEmpty() }
        },
        encode = { words ->
            if (words.isEmpty()) null else words.joinToString("\n")
        },
    )
