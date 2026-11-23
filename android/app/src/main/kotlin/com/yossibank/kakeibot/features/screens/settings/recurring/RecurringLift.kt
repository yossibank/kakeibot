package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import kotlin.math.roundToInt

class RecurringLift {
    var hideTarget by mutableStateOf<Rect?>(null)
    var origin by mutableStateOf(Offset.Zero)

    var id: Identifier<Recurring>? by mutableStateOf(null)
        private set

    private var startY by mutableFloatStateOf(0f)
    private var dragY by mutableFloatStateOf(0f)
    private var pointer by mutableStateOf<Offset?>(null)

    val y: Float
        get() = startY + dragY

    val isOverHide: Boolean
        get() {
            val pointer = pointer ?: return false
            return hideTarget?.contains(pointer) ?: false
        }

    fun start(
        id: Identifier<Recurring>,
        top: Float,
        touch: Offset,
    ) {
        this.id = id
        startY = top
        dragY = 0f
        pointer = origin.copy(y = origin.y + top) + touch
    }

    fun drag(
        amount: Offset,
        slot: Float,
    ): Int {
        dragY += amount.y
        pointer = pointer?.plus(amount)

        return (y / slot).roundToInt()
    }

    fun end(): Identifier<Recurring>? {
        val hiding = id.takeIf { isOverHide }

        cancel()

        return hiding
    }

    fun cancel() {
        id = null
        pointer = null
    }
}
