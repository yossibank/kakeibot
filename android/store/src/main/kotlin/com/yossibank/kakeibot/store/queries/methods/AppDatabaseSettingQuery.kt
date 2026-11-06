package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged

fun <Value> AppDatabase.settingUpdates(key: SettingKey<Value>): Flow<Value> = observation("setting") {
    fetchSetting(key)
}.distinctUntilChanged()

suspend fun <Value> AppDatabase.setting(key: SettingKey<Value>): Value = read {
    fetchSetting(key)
}

internal suspend fun <Value> AppDatabase.fetchSetting(key: SettingKey<Value>): Value = key.read(this)
