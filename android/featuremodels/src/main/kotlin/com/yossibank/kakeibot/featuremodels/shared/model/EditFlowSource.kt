package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.featuremodels.shared.notice.Deletion

interface EditFlowSource<Saved : Any> {
    val isEditing: Boolean
    val isChanged: Boolean
    val problem: String?

    suspend fun store(): Saved?

    val readyTitle: String
        get() = if (isEditing) "変更を保存" else "追加する"

    val isHidden: Boolean
        get() = false

    val asksBeforeHiding: Boolean
        get() = false

    fun rest(): Boolean = false

    fun keepsOpen(after: Saved): Boolean = false

    suspend fun storeHidden(isHidden: Boolean) {}

    suspend fun remove(): Deletion? = null

    fun hideFailedMessage(error: Exception): String = ModelTask.saveFailed

    fun deleteFailedMessage(error: Exception): String = ModelTask.deleteFailed
}
