package com.yossibank.kakeibot.featuremodels.screens.entry.sheet

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.RemovedItem
import com.yossibank.kakeibot.featuremodels.screens.entry.model.addItem
import com.yossibank.kakeibot.featuremodels.screens.entry.model.removeItem
import com.yossibank.kakeibot.featuremodels.screens.entry.model.restoreItem
import com.yossibank.kakeibot.featuremodels.screens.entry.model.unitPrice
import com.yossibank.kakeibot.featuremodels.screens.entry.model.updateItem
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenEditable
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenWait
import com.yossibank.kakeibot.featuremodels.shared.model.UndoNotice
import kotlin.math.abs

class EntryItemModel(
    wait: ScreenWait,
) {
    val state = State(wait)

    enum class Target {
        Unit,
        Quantity,
    }

    data class Editing(
        val index: Int,
        internal val item: EntryItem.Draft,
    )

    data class Draft(
        val name: String = "",
        val taxRate: AmountCalculator.TaxRate? = null,
        val target: Target = Target.Unit,
        val unit: AmountCalculator = AmountCalculator(),
        val quantity: AmountCalculator = AmountCalculator(amount = 1),
        val isDiscount: Boolean = false,
        val editing: Editing? = null,
    ) {
        val trimmedName: String
            get() = name.trim()

        val quantityValue: Int
            get() = maxOf(1, quantity.amount)

        val activeCalculator: AmountCalculator
            get() = if (target == Target.Unit) unit else quantity

        val lineQuantity: Int
            get() = keptItem?.quantity ?: quantityValue

        val lineAmount: Long
            get() = keptItem?.amount?.toLong()
                ?: ((if (isDiscount) -1L else 1L) * unit.amount * quantityValue)

        val canSubmit: Boolean
            get() {
                if (trimmedName.isEmpty()) {
                    return false
                }

                if (keptItem != null) {
                    return true
                }

                return unit.amount > 0 && abs(lineAmount) <= AmountCalculator.maxValue
            }

        fun isEditing(index: Int): Boolean = editing?.index == index

        fun pressed(key: AmountCalculator.Key): Draft = when (target) {
            Target.Unit -> copy(unit = unit.press(key))
            Target.Quantity -> copy(quantity = quantity.press(key))
        }

        fun halved(): Draft = copy(
            target = Target.Unit,
            unit = AmountCalculator(amount = unit.amount / 2),
        )

        fun afterRemoving(index: Int): Draft {
            val editing = editing ?: return this

            if (editing.index <= index) {
                return this
            }

            return copy(editing = editing.copy(index = editing.index - 1))
        }

        fun afterRestoring(index: Int): Draft {
            val editing = editing ?: return this

            if (index > editing.index) {
                return this
            }

            return copy(editing = editing.copy(index = editing.index + 1))
        }

        private val keptItem: EntryItem.Draft?
            get() {
                val item = editing?.item ?: return null
                val price = item.unitPrice()

                val isSame = unit.amount == abs(price.first) &&
                    quantity.amount == price.second &&
                    isDiscount == (item.amount < 0)

                return if (isSame) item else null
            }

        companion object {
            fun editing(
                index: Int,
                item: EntryItem.Draft,
            ): Draft {
                val price = item.unitPrice()

                return Draft(
                    name = item.name,
                    taxRate = item.taxRate,
                    unit = AmountCalculator(amount = abs(price.first)),
                    quantity = AmountCalculator(amount = price.second),
                    isDiscount = item.amount < 0,
                    editing = Editing(index = index, item = item),
                )
            }
        }
    }

    data class Fields(
        val draft: Draft = Draft(),
    ) : ScreenEditable

    class Presented : ScreenEditable {
        var isSlipOpen: Boolean by mutableStateOf(false)
            private set

        internal fun openSlip() {
            isSlipOpen = true
        }

        internal fun closeSlip() {
            isSlipOpen = false
        }
    }

    class Notices(
        wait: ScreenWait,
    ) {
        val removed = UndoNotice<RemovedItem>(wait)
    }

    class State(
        wait: ScreenWait,
    ) {
        val notices = Notices(wait)
        val presented = Presented()

        var fields: Fields by mutableStateOf(Fields())
            private set

        fun setName(name: String) {
            change { copy(name = name) }
        }

        fun select(taxRate: AmountCalculator.TaxRate?) {
            change { copy(taxRate = taxRate) }
        }

        fun enter(target: Target) {
            change { copy(target = target) }
        }

        fun toggleDiscount() {
            change { copy(isDiscount = !isDiscount) }
        }

        fun press(key: AmountCalculator.Key) {
            change { pressed(key) }
        }

        fun halveUnit() {
            change { halved() }
        }

        fun close() {
            presented.closeSlip()
            change { copy(editing = null) }
        }

        internal fun change(change: Draft.() -> Draft) {
            fields = fields.copy(draft = fields.draft.change())
        }
    }

    fun open(entry: EntryModel) {
        reset(entry)
        state.presented.openSlip()
    }

    fun edit(
        index: Int,
        item: EntryItem.Draft,
    ) {
        state.change { Draft.editing(index = index, item = item) }
        state.presented.openSlip()
    }

    fun reset(entry: EntryModel) {
        val taxRate = entry.state.fields.form.items.lastOrNull()?.taxRate
        state.change { Draft(taxRate = taxRate) }
    }

    fun submit(entry: EntryModel) {
        val draft = state.fields.draft

        if (!draft.canSubmit) {
            return
        }

        val item = EntryItem.Draft(
            name = draft.trimmedName,
            quantity = draft.lineQuantity,
            amount = draft.lineAmount.toInt(),
            taxRate = draft.taxRate,
        )

        val editing = draft.editing

        if (editing != null) {
            entry.updateItem(
                index = editing.index,
                item = item,
            )

            state.close()
        } else {
            entry.addItem(item)
            reset(entry)
        }
    }

    fun remove(
        entry: EntryModel,
        index: Int,
    ) {
        if (state.fields.draft.isEditing(index)) {
            reset(entry)
        } else {
            state.change { afterRemoving(index) }
        }

        entry.removeItem(index)?.let(state.notices.removed::show)
    }

    fun restore(entry: EntryModel) {
        val removed = state.notices.removed.current ?: return

        state.change { afterRestoring(removed.index) }
        entry.restoreItem(removed)
        state.notices.removed.dismiss()
    }
}
