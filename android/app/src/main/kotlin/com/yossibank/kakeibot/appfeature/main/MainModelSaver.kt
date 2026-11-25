package com.yossibank.kakeibot.appfeature.main

import androidx.compose.runtime.Composable
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import com.yossibank.kakeibot.featuremodels.screens.main.MainModel
import com.yossibank.kakeibot.featuremodels.screens.main.restore
import com.yossibank.kakeibot.featuremodels.screens.main.saved

@Composable
internal fun rememberMainModel(): MainModel = rememberSaveable(saver = saver) { MainModel() }

private val saver: Saver<MainModel, List<String>> = Saver(
    save = { it.saved() },
    restore = { MainModel.restore(it) },
)
