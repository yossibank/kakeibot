package com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint

import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming

interface SettingsFoldModel : ScreenPerforming {
    suspend fun loadFold(fold: SettingsFoldInput)

    suspend fun setFold(
        fold: SettingsFoldInput,
        isClosed: Boolean,
    )
}
