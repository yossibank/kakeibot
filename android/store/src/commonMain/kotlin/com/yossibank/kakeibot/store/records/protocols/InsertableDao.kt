package com.yossibank.kakeibot.store.records.protocols

import androidx.room.Insert

interface InsertableDao<Record> {
    @Insert
    suspend fun insert(record: Record)
}
