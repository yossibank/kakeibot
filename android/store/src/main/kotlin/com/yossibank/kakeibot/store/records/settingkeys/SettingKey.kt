package com.yossibank.kakeibot.store.records.settingkeys

import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.records.rows.record

class SettingKey<Value> internal constructor(
    val defaultValue: Value,
    internal val read: suspend (AppDatabase) -> Value,
    internal val write: suspend (Value, AppDatabase) -> Unit,
) {
    companion object
}

internal fun <Value> SettingKey.Companion.of(
    key: Setting.Key,
    default: Value,
    decode: (String) -> Value?,
    encode: (Value) -> String?,
): SettingKey<Value> = SettingKey(
    defaultValue = default,
    read = { database ->
        val setting = database.settingDao().find(key.rawValue)

        setting?.let { decode(it.value) } ?: default
    },
    write = { value, database ->
        val text = encode(value)

        if (text == null) {
            database.settingDao().delete(key.rawValue)
        } else {
            val setting = Setting(
                key = key,
                value = text,
            )

            database.settingDao().save(setting.record())
        }
    },
)

internal fun <Value> SettingKey.Companion.raw(
    key: Setting.Key,
    default: Value,
    parse: (String) -> Value?,
    rawValue: (Value) -> String,
): SettingKey<Value> = of(
    key = key,
    default = default,
    decode = parse,
    encode = rawValue,
)

internal fun SettingKey.Companion.screens(
    key: Setting.Key,
    default: Set<SettingsScreen> = emptySet(),
): SettingKey<Set<SettingsScreen>> = of(
    key = key,
    default = default,
    decode = { text ->
        text.split(",")
            .mapNotNull { SettingsScreen.of(it) }
            .toSet()
    },
    encode = { screens ->
        val names = screens.map { it.rawValue }.sorted()

        if (names.isEmpty()) null else names.joinToString(",")
    },
)

internal fun SettingKey.Companion.flag(key: Setting.Key): SettingKey<Boolean> = of(
    key = key,
    default = false,
    decode = { it == "true" },
    encode = { if (it) "true" else null },
)

internal fun SettingKey.Companion.switch(key: Setting.Key): SettingKey<Boolean> = of(
    key = key,
    default = true,
    decode = { it != "false" },
    encode = { if (it) null else "false" },
)

internal fun decimalInt(text: String): Int? {
    val digits = if (text.startsWith("+") || text.startsWith("-")) text.drop(1) else text

    if (digits.isEmpty() || digits.any { it !in '0'..'9' }) {
        return null
    }

    return text.toIntOrNull()
}
