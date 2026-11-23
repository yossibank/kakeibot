package com.yossibank.kakeibot.store.records.protocols

import androidx.room.Update

interface UpdatableDao<Record> : InsertableDao<Record> {
    @Update
    suspend fun update(record: Record)
}
