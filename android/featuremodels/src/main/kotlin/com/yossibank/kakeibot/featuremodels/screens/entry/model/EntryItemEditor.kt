package com.yossibank.kakeibot.featuremodels.screens.entry.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenWait
import com.yossibank.kakeibot.featuremodels.shared.model.UndoNotice
import kotlin.math.abs

class EntryItemEditor(
    wait: ScreenWait,
) {
    var isOpen by mutableStateOf(false)
    var name by mutableStateOf("")
    var unit by mutableStateOf(AmountCalculator())
    var quantity by mutableStateOf(AmountCalculator(amount = 1))
    var target by mutableStateOf(Target.Unit)
    var editingIndex: Int? by mutableStateOf(null)
    var editingItem: EntryItem.Draft? by mutableStateOf(null)
    var taxRate: AmountCalculator.TaxRate? by mutableStateOf(null)
    var isDiscount by mutableStateOf(false)

    val removed = UndoNotice<RemovedItem>(wait)

    enum class Target {
        Unit,
        Quantity,
    }

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

    fun open(model: EntryModel) {
        reset(model)
        isOpen = true
    }

    fun edit(
        index: Int,
        item: EntryItem.Draft,
    ) {
        val price = item.unitPrice()

        name = item.name
        unit = AmountCalculator(amount = abs(price.first))
        quantity = AmountCalculator(amount = price.second)
        target = Target.Unit
        editingIndex = index
        editingItem = item
        taxRate = item.taxRate
        isDiscount = item.amount < 0
        isOpen = true
    }

    fun press(key: AmountCalculator.Key) {
        when (target) {
            Target.Unit -> unit = unit.press(key)
            Target.Quantity -> quantity = quantity.press(key)
        }
    }

    fun halveUnit() {
        target = Target.Unit
        unit = AmountCalculator(amount = unit.amount / 2)
    }

    fun close() {
        isOpen = false
        editingIndex = null
        editingItem = null
    }

    fun reset(model: EntryModel) {
        name = ""
        unit = AmountCalculator()
        quantity = AmountCalculator(amount = 1)
        target = Target.Unit
        editingIndex = null
        editingItem = null
        taxRate = model.state.form.items.lastOrNull()?.taxRate
        isDiscount = false
    }

    fun submit(model: EntryModel) {
        if (!canSubmit) {
            return
        }

        val item = EntryItem.Draft(
            name = trimmedName,
            quantity = lineQuantity,
            amount = lineAmount.toInt(),
            taxRate = taxRate,
        )

        val index = editingIndex

        if (index != null) {
            model.updateItem(
                index = index,
                item = item,
            )

            close()
        } else {
            model.addItem(item)
            reset(model)
        }
    }

    fun remove(
        model: EntryModel,
        index: Int,
    ) {
        val editing = editingIndex

        if (editing == index) {
            reset(model)
        } else if (editing != null && editing > index) {
            editingIndex = editing - 1
        }

        model.removeItem(index)?.let(removed::show)
    }

    fun restore(model: EntryModel) {
        val item = removed.current ?: return
        val editing = editingIndex

        if (editing != null && item.index <= editing) {
            editingIndex = editing + 1
        }

        model.restoreItem(item)
        removed.dismiss()
    }

    private val keptItem: EntryItem.Draft?
        get() {
            val item = editingItem ?: return null
            val price = item.unitPrice()

            val isSame = unit.amount == abs(price.first) &&
                quantity.amount == price.second &&
                isDiscount == (item.amount < 0)

            return if (isSame) item else null
        }
}
