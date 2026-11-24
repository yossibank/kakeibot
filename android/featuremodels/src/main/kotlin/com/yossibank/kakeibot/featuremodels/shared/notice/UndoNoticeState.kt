package com.yossibank.kakeibot.featuremodels.shared.notice

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.delay

class UndoNoticeState<Item : Any> {
    private data class Shown<Item>(
        val id: Int,
        val item: Item,
    )

    private var shown: Shown<Item>? by mutableStateOf(null)

    private var count = 0

    val current: Item?
        get() = shown?.item

    fun show(item: Item) {
        count += 1

        shown = Shown(
            id = count,
            item = item,
        )
    }

    fun dismiss() {
        shown = null
    }

    @Composable
    fun Timer() {
        val id = shown?.id ?: return

        LaunchedEffect(id) {
            delay(MILLIS)

            if (shown?.id == id) {
                dismiss()
            }
        }
    }

    companion object {
        const val MILLIS = 4_000L
    }
}
