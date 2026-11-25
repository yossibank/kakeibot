package com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint

interface SettingsFoldModel {
    suspend fun loadFold(fold: SettingsFoldInput)

    suspend fun setFold(
        fold: SettingsFoldInput,
        isClosed: Boolean,
    )
}
