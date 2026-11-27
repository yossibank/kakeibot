package com.yossibank.kakeibot.featuremodels.shared.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Job
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

class UndoNotice<Item : Any>(
    private val wait: ScreenWait,
) {
    private var showing: Showing<Item>? by mutableStateOf(null)

    private var count = 0
    private var timer: Job? = null

    private data class Showing<Item>(
        val id: Int,
        val item: Item,
    )

    val current: Item?
        get() = showing?.item

    val id: Int?
        get() = showing?.id

    fun show(
        item: Item,
        duration: Duration = UndoNotice.duration,
    ) {
        count += 1

        val id = count

        showing = Showing(
            id = id,
            item = item,
        )

        timer?.cancel()

        timer = wait.after(duration) {
            if (showing?.id == id) {
                showing = null
            }
        }
    }

    fun dismiss() {
        timer?.cancel()
        timer = null
        showing = null
    }

    fun take(): Item? {
        val item = current
        dismiss()
        return item
    }

    companion object {
        val duration = 4.seconds
    }
}
