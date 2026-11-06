package com.yossibank.kakeibot.store.records.settingkeys

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.shared.InstantSerializer
import java.time.Instant

val SettingKey.Companion.receiptSavedCount: SettingKey<Int>
    get() = of(
        key = Setting.Key.receiptSavedCount,
        default = 0,
        decode = { text -> decimalInt(text)?.let { maxOf(it, 0) } },
        encode = { if (it > 0) it.toString() else null },
    )

val SettingKey.Companion.feeCategory: SettingKey<Identifier<EntryCategory>?>
    get() = categoryId(Setting.Key.feeCategoryId)

val SettingKey.Companion.transferOutCategory: SettingKey<Identifier<EntryCategory>?>
    get() = categoryId(Setting.Key.transferOutCategoryId)

val SettingKey.Companion.transferInCategory: SettingKey<Identifier<EntryCategory>?>
    get() = categoryId(Setting.Key.transferInCategoryId)

val SettingKey.Companion.backupExportedAt: SettingKey<Instant?>
    get() = of(
        key = Setting.Key.backupExportedAt,
        default = null,
        decode = { InstantSerializer.parse(it) },
        encode = { it?.let(InstantSerializer::format) },
    )

val SettingKey.Companion.reviewRequestedVersion: SettingKey<String?>
    get() = text(Setting.Key.reviewRequestedVersion)

val SettingKey.Companion.whatsNewSeenVersion: SettingKey<String?>
    get() = text(Setting.Key.whatsNewSeenVersion)

val SettingKey.Companion.onboardingCompleted: SettingKey<Boolean>
    get() = flag(Setting.Key.onboardingCompleted)

val SettingKey.Companion.setupCardClosed: SettingKey<Boolean>
    get() = flag(Setting.Key.setupCardClosed)

val SettingKey.Companion.entryOpened: SettingKey<Boolean>
    get() = flag(Setting.Key.entryOpened)

val SettingKey.Companion.receiptGuideHidden: SettingKey<Boolean>
    get() = flag(Setting.Key.receiptGuideHidden)

val SettingKey.Companion.settingsOpened: SettingKey<Boolean>
    get() = flag(Setting.Key.settingsOpened)

val SettingKey.Companion.tabTitles: SettingKey<Boolean>
    get() = switch(Setting.Key.tabTitles)

val SettingKey.Companion.entryStartsWithAmount: SettingKey<Boolean>
    get() = switch(Setting.Key.entryStartsWithAmount)

val SettingKey.Companion.haptics: SettingKey<Boolean>
    get() = switch(Setting.Key.haptics)

val SettingKey.Companion.decorations: SettingKey<Boolean>
    get() = switch(Setting.Key.decorations)

private fun SettingKey.Companion.categoryId(key: Setting.Key): SettingKey<Identifier<EntryCategory>?> = of(
    key = key,
    default = null,
    decode = { Identifier.parse(it) },
    encode = { it?.toString() },
)

private fun SettingKey.Companion.text(key: Setting.Key): SettingKey<String?> = of(
    key = key,
    default = null,
    decode = { it },
    encode = { it },
)
