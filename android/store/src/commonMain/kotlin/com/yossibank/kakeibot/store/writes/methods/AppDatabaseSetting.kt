package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey

suspend fun <Value> AppDatabase.setSetting(
    key: SettingKey<Value>,
    to: Value,
) {
    write {
        storeSetting(
            key = key,
            to = to,
        )
    }
}

internal suspend fun <Value> AppDatabase.storeSetting(
    key: SettingKey<Value>,
    to: Value,
) {
    key.write(to, this)
}
