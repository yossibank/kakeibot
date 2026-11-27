package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.core.concepts.date.LocalDate

interface TabScreenModel {
    val errorNotice: ErrorNotice

    val isLoadFailed: Boolean

    fun setToday(today: LocalDate)

    suspend fun observe()

    fun retry()
}
