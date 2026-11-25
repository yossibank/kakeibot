package com.yossibank.kakeibot.featuremodels.shared.settingsparts.input

import com.yossibank.kakeibot.store.writes.types.Deletion

class SettingsEditOutcome<Saved : Any> internal constructor(
    val saved: Saved? = null,
    val isHidden: Boolean? = null,
    val deletion: Deletion? = null,
    val closes: Boolean = true,
)
