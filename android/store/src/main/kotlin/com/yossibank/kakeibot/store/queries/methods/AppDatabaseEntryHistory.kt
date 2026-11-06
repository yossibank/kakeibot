package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.queries.types.EntryHistory
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.reviewRequestedVersion

suspend fun AppDatabase.entryHistory(): EntryHistory = read {
    fetchEntryHistory()
}

suspend fun AppDatabase.claimReviewRequest(
    version: String,
    isReady: (EntryHistory) -> Boolean,
): Boolean = write {
    if (fetchSetting(SettingKey.reviewRequestedVersion) == version) {
        return@write false
    }

    if (!isReady(fetchEntryHistory())) {
        return@write false
    }

    SettingKey.reviewRequestedVersion.write(version, this)

    true
}

internal suspend fun AppDatabase.fetchEntryHistory(): EntryHistory {
    val count = entryDao().count()
    val first = entryDao().firstCreated()?.decoded(EntryRecord::entry)

    return EntryHistory(
        count = count,
        firstCreatedAt = first?.createdAt,
    )
}
