package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.queries.methods.fetchSetting
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.receiptSavedCount

suspend fun AppDatabase.countReceiptSave() {
    write {
        val count = fetchSetting(SettingKey.receiptSavedCount)

        storeSetting(
            key = SettingKey.receiptSavedCount,
            to = count + 1,
        )
    }
}
