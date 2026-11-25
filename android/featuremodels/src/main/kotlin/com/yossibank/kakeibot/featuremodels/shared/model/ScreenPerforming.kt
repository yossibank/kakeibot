package com.yossibank.kakeibot.featuremodels.shared.model

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

interface ScreenPerforming

fun <Model : ScreenPerforming> Model.perform(work: suspend (Model) -> Unit): Job {
    val model = this
    return performing.launch { work(model) }
}

private val performing = CoroutineScope(SupervisorJob() + Dispatchers.Main)
