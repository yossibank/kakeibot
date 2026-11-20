package com.yossibank.kakeibot.features.screens.entry.sheet

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.designsystem.components.date.shortName
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.model.RemovedItem
import com.yossibank.kakeibot.features.screens.entry.model.addItem
import com.yossibank.kakeibot.features.screens.entry.model.adjustToItems
import com.yossibank.kakeibot.features.screens.entry.model.canAdjustToItems
import com.yossibank.kakeibot.features.screens.entry.model.hasItemAdjustment
import com.yossibank.kakeibot.features.screens.entry.model.itemAdjustment
import com.yossibank.kakeibot.features.screens.entry.model.itemCount
import com.yossibank.kakeibot.features.screens.entry.model.itemNameSuggestions
import com.yossibank.kakeibot.features.screens.entry.model.itemTotals
import com.yossibank.kakeibot.features.screens.entry.model.quantityText
import com.yossibank.kakeibot.features.screens.entry.model.removeItem
import com.yossibank.kakeibot.features.screens.entry.model.restoreItem
import com.yossibank.kakeibot.features.screens.entry.model.setTaxIncluded
import com.yossibank.kakeibot.features.screens.entry.model.store
import com.yossibank.kakeibot.features.screens.entry.model.unitPrice
import com.yossibank.kakeibot.features.screens.entry.model.updateItem
import kotlinx.coroutines.delay

@Composable
fun EntryItemSheet(
    model: EntryModel,
    onClose: () -> Unit,
) {
    val input = remember(model) { ItemInput() }

    BackHandler {
        if (input.isOpen) {
            input.close()
        } else {
            onClose()
        }
    }

    LaunchedEffect(input.removed) {
        val removed = input.removed ?: return@LaunchedEffect

        delay(REMOVED_NOTICE_MILLIS)

        if (input.removed == removed) {
            input.removed = null
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Palette.background)
                .pointerInput(Unit) {}
                .statusBarsPadding()
                .navigationBarsPadding()
                .imePadding(),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(
                        horizontal = 20.dp,
                        vertical = 12.dp,
                    ),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "品目",
                    color = Palette.text,
                    style = textFont(
                        size = FontSize.Body,
                        weight = FontWeight.SemiBold,
                    ),
                )

                RingButton(
                    icon = R.drawable.ic_check,
                    isProminent = true,
                    onSelect = onClose,
                    modifier = Modifier.align(Alignment.CenterEnd),
                )
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(
                        horizontal = 20.dp,
                        vertical = 8.dp,
                    ),
            ) {
                Receipt(
                    model = model,
                    input = input,
                )
            }

            if (input.isOpen) {
                ItemSlip(
                    model = model,
                    input = input,
                )
            } else {
                AddBar(onAdd = { input.open(model) })
            }
        }

        if (input.removed != null) {
            RemovedNotice(
                onUndo = { input.restore(model) },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .navigationBarsPadding()
                    .padding(
                        start = 20.dp,
                        end = 20.dp,
                        bottom = 76.dp,
                    ),
            )
        }
    }
}

@Composable
private fun RemovedNotice(
    onUndo: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(16.dp))

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.panel)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = shape,
            ).padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_trash),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = Palette.accent,
        )

        Text(
            text = "品目を消しました",
            modifier = Modifier.weight(1f),
            color = Palette.text,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )

        Chip(
            title = "取り消す",
            isSelected = false,
            onSelect = onUndo,
        )
    }
}

private class ItemInput {
    enum class Target {
        Unit,
        Quantity,
    }

    var isOpen by mutableStateOf(false)
    var name by mutableStateOf("")
    var unit by mutableStateOf(AmountCalculator())
    var quantity by mutableStateOf(AmountCalculator(amount = 1))
    var target by mutableStateOf(Target.Unit)
    var editingIndex: Int? by mutableStateOf(null)
    var editingItem: EntryItem.Draft? by mutableStateOf(null)
    var taxRate: AmountCalculator.TaxRate? by mutableStateOf(null)
    var isDiscount by mutableStateOf(false)
    var removed: RemovedItem? by mutableStateOf(null)

    val trimmedName: String
        get() = name.trim()

    val quantityValue: Int
        get() = maxOf(1, quantity.amount)

    val activeCalculator: AmountCalculator
        get() = if (target == Target.Unit) unit else quantity

    private val keptItem: EntryItem.Draft?
        get() {
            val item = editingItem ?: return null
            val price = item.unitPrice()

            val isSame = unit.amount == kotlin.math.abs(price.first) &&
                quantity.amount == price.second &&
                isDiscount == (item.amount < 0)

            return if (isSame) item else null
        }

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

            return unit.amount > 0 && kotlin.math.abs(lineAmount) <= AmountCalculator.maxValue
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
        unit = AmountCalculator(amount = kotlin.math.abs(price.first))
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
        taxRate = model.items.lastOrNull()?.taxRate
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

        removed = model.removeItem(index)
    }

    fun restore(model: EntryModel) {
        val removed = removed ?: return
        val editing = editingIndex

        if (editing != null && removed.index <= editing) {
            editingIndex = editing + 1
        }

        model.restoreItem(removed)
        this.removed = null
    }
}

@Composable
private fun Receipt(
    model: EntryModel,
    input: ItemInput,
) {
    val totals = model.itemTotals
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(8.dp))

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.paper)
            .border(
                width = 1.dp,
                color = Palette.paperEdge,
                shape = shape,
            ).padding(
                horizontal = 20.dp,
                vertical = 24.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            val date = model.date

            Text(
                text = "${date.year}/${date.monthDayText}（${date.weekday.shortName}）",
                color = Palette.subtext,
                style = textFont(size = FontSize.Caption),
            )

            StoreField(model = model)
        }

        Rule()

        if (model.items.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(
                    text = "品目はまだありません",
                    color = Palette.subtext,
                    style = textFont(size = FontSize.Small),
                )

                Text(
                    text = "下の「品目を追加」から追加できます。",
                    color = Palette.hint,
                    style = textFont(size = FontSize.Caption),
                )
            }
        } else {
            Column {
                model.items.forEachIndexed { index, item ->
                    key(index, item) {
                        ItemRow(
                            item = item,
                            isEditing = input.isOpen && input.editingIndex == index,
                            showsRate = model.items.map { it.taxRate }.toSet().size > 1,
                            onSelect = { input.edit(index, item) },
                            onRemove = { input.remove(model, index) },
                        )
                    }
                }
            }
        }

        Rule()

        SummaryLine(
            title = "小計",
            amount = totals.subtotal,
        )

        if (totals.taxes.isNotEmpty()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "税の計算",
                    modifier = Modifier.weight(1f),
                    color = Palette.subtext,
                    style = textFont(size = FontSize.Caption),
                )

                SegmentSwitch(
                    selection = model.taxIncluded,
                    options = listOf(false to "外税", true to "内税"),
                    onSelect = model::setTaxIncluded,
                )
            }

            totals.taxes.forEach { tax ->
                val title = if (model.taxIncluded) "内消費税" else "消費税"

                SummaryLine(
                    title = "${tax.rate.rawValue}%対象 ${AmountText.text(tax.base.toInt())}",
                    amount = null,
                    detail = "$title ${AmountText.text(tax.amount.toInt())}",
                )
            }
        }

        if (model.hasItemAdjustment) {
            AdjustmentLine(model = model)
        }

        Rule()

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "合計",
                modifier = Modifier.weight(1f),
                color = Palette.text,
                style = textFont(
                    size = FontSize.Small,
                    weight = FontWeight.SemiBold,
                ),
            )

            Text(
                text = AmountText.text(model.amount),
                color = Palette.accentStrong,
                maxLines = 1,
                style = displayFont(
                    size = FontSize.Display,
                    weight = FontWeight.Bold,
                ),
            )
        }

        if (model.items.isNotEmpty()) {
            Row {
                Text(
                    text = "お買上点数",
                    modifier = Modifier.weight(1f),
                    color = Palette.subtext,
                    style = textFont(size = FontSize.Caption),
                )

                Text(
                    text = "${model.itemCount}点",
                    color = Palette.subtext,
                    style = textFont(size = FontSize.Caption),
                )
            }
        }
    }
}

@Composable
private fun StoreField(model: EntryModel) {
    val style = textFont(
        size = FontSize.Body,
        weight = FontWeight.SemiBold,
    ).copy(
        color = Palette.text,
        textAlign = TextAlign.Center,
    )

    BasicTextField(
        value = model.store,
        onValueChange = { model.store = it },
        modifier = Modifier.fillMaxWidth(),
        textStyle = style,
        singleLine = true,
        cursorBrush = SolidColor(Palette.accent),
        decorationBox = { field ->
            Box(contentAlignment = Alignment.Center) {
                if (model.store.isEmpty()) {
                    Text(
                        text = "店名を入れる",
                        color = Palette.hint,
                        style = style,
                    )
                }

                field()
            }
        },
    )
}

@Composable
private fun ItemRow(
    item: EntryItem.Draft,
    isEditing: Boolean,
    showsRate: Boolean,
    onSelect: () -> Unit,
    onRemove: () -> Unit,
) {
    val state = rememberSwipeToDismissBoxState()

    LaunchedEffect(state.currentValue) {
        if (state.currentValue == SwipeToDismissBoxValue.EndToStart) {
            onRemove()
        }
    }

    SwipeToDismissBox(
        state = state,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Palette.rose),
                contentAlignment = Alignment.CenterEnd,
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_trash),
                    contentDescription = null,
                    modifier = Modifier
                        .padding(end = 16.dp)
                        .size(20.dp),
                    tint = Palette.backgroundTop,
                )
            }
        },
    ) {
        ItemLine(
            item = item,
            isEditing = isEditing,
            showsRate = showsRate,
            onSelect = onSelect,
        )
    }
}

@Composable
private fun ItemLine(
    item: EntryItem.Draft,
    isEditing: Boolean,
    showsRate: Boolean,
    onSelect: () -> Unit,
) {
    val isNegative = item.amount < 0
    val fill = if (isEditing) Palette.accent.opacity(Emphasis.Subtle) else Color.Transparent

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Palette.paper)
            .background(fill)
            .clickable(onClick = onSelect)
            .padding(
                horizontal = 4.dp,
                vertical = 8.dp,
            ),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(start = if (isNegative) 12.dp else 0.dp),
            verticalArrangement = Arrangement.spacedBy(1.dp),
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = item.trimmedName,
                    color = if (isNegative) Palette.rose else Palette.text,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = textFont(size = FontSize.Small),
                )

                val rate = item.taxRate

                if (showsRate && rate != null) {
                    Text(
                        text = "${rate.rawValue}%",
                        color = Palette.subtext,
                        style = textFont(size = FontSize.Micro),
                    )
                }
            }

            item.quantityText()?.let { text ->
                Text(
                    text = text,
                    color = Palette.subtext,
                    style = textFont(size = FontSize.Caption),
                )
            }
        }

        Text(
            text = AmountText.text(item.amount),
            color = if (isNegative) Palette.rose else Palette.text,
            style = textFont(size = FontSize.Small),
        )
    }
}

@Composable
private fun SummaryLine(
    title: String,
    amount: Long?,
    detail: String? = null,
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = title,
            modifier = Modifier.weight(1f),
            color = Palette.subtext,
            style = textFont(size = FontSize.Small),
        )

        Text(
            text = detail ?: AmountText.text(amount?.toInt() ?: 0),
            color = Palette.text,
            style = textFont(size = FontSize.Small),
        )
    }
}

@Composable
private fun AdjustmentLine(model: EntryModel) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "差額",
            color = Palette.amber,
            style = textFont(size = FontSize.Small),
        )

        if (model.canAdjustToItems) {
            Box(
                modifier = Modifier
                    .height(32.dp)
                    .clip(CircleShape)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Medium),
                        shape = CircleShape,
                    ).clickable(onClick = model::adjustToItems)
                    .padding(horizontal = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "調整",
                    color = Palette.accent,
                    style = textFont(
                        size = FontSize.Caption,
                        weight = FontWeight.SemiBold,
                    ),
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        Text(
            text = AmountText.text(model.itemAdjustment.toInt()),
            color = Palette.amber,
            style = textFont(size = FontSize.Small),
        )
    }
}

@Composable
private fun AddBar(onAdd: () -> Unit) {
    Box(
        modifier = Modifier
            .padding(
                horizontal = 20.dp,
                vertical = 8.dp,
            ).fillMaxWidth()
            .height(52.dp)
            .clip(CircleShape)
            .background(Palette.accent)
            .clickable(onClick = onAdd),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "＋ 品目を追加",
            color = Palette.backgroundTop,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun ItemSlip(
    model: EntryModel,
    input: ItemInput,
) {
    val focus = LocalFocusManager.current

    val shape = RoundedCornerShape(
        topStart = 20.dp,
        topEnd = 20.dp,
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.paper)
            .border(
                width = 1.dp,
                color = Palette.paperEdge,
                shape = shape,
            ).padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = input.editingIndex?.let { "品目 ${it + 1} を変更" } ?: "品目を追加",
                modifier = Modifier.weight(1f),
                color = Palette.text,
                style = textFont(
                    size = FontSize.Small,
                    weight = FontWeight.SemiBold,
                ),
            )

            RingButton(
                icon = R.drawable.ic_close,
                isProminent = false,
                onSelect = input::close,
            )
        }

        NameField(input = input)

        val suggestions = model.itemNameSuggestions(input.name)

        if (suggestions.isNotEmpty()) {
            Row(
                modifier = Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                suggestions.forEach { suggestion ->
                    Chip(
                        title = suggestion,
                        isSelected = false,
                        onSelect = {
                            focus.clearFocus()
                            input.name = suggestion
                        },
                    )
                }
            }
        }

        Equation(input = input)

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(
                null to "税込",
                AmountCalculator.TaxRate.reduced to "8%",
                AmountCalculator.TaxRate.standard to "10%",
            ).forEach { (rate, title) ->
                Chip(
                    title = title,
                    isSelected = input.taxRate == rate,
                    onSelect = { input.taxRate = rate },
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            Chip(
                title = "値引",
                isSelected = input.isDiscount,
                onSelect = { input.isDiscount = !input.isDiscount },
            )

            Chip(
                title = "半額",
                isSelected = false,
                onSelect = input::halveUnit,
            )
        }

        Keypad(
            calculator = input.activeCalculator,
            onKey = { key ->
                focus.clearFocus()
                input.press(key)
            },
            keyHeight = 44.dp,
        )

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
                .clip(CircleShape)
                .background(
                    if (input.canSubmit) Palette.accent else Palette.accent.opacity(Emphasis.Muted),
                )
                .clickable(enabled = input.canSubmit) {
                    focus.clearFocus()
                    input.submit(model)
                },
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = if (input.editingIndex == null) "追加" else "変更",
                color = Palette.backgroundTop,
                style = textFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
            )
        }
    }
}

@Composable
private fun NameField(input: ItemInput) {
    val focus = LocalFocusManager.current
    val style = textFont(size = FontSize.Body)
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(12.dp))

    BasicTextField(
        value = input.name,
        onValueChange = { input.name = it },
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.panel)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Soft),
                shape = shape,
            ).padding(
                horizontal = 12.dp,
                vertical = 10.dp,
            ),
        textStyle = style.copy(color = Palette.text),
        singleLine = true,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
        keyboardActions = KeyboardActions(onDone = { focus.clearFocus() }),
        cursorBrush = SolidColor(Palette.accent),
        decorationBox = { field ->
            if (input.name.isEmpty()) {
                Text(
                    text = "品名",
                    color = Palette.hint,
                    style = style,
                )
            }

            field()
        },
    )
}

@Composable
private fun Equation(input: ItemInput) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Token(
            label = "単価",
            value = AmountText.text(input.unit.amount),
            isSelected = input.target == ItemInput.Target.Unit,
            onSelect = { input.target = ItemInput.Target.Unit },
        )

        Operator(text = "×")

        Token(
            label = "数量",
            value = input.quantityValue.toString(),
            isSelected = input.target == ItemInput.Target.Quantity,
            onSelect = { input.target = ItemInput.Target.Quantity },
        )

        Spacer(modifier = Modifier.weight(1f))

        Operator(text = "=")

        Text(
            text = AmountText.text(input.lineAmount.toInt()),
            color = if (input.isDiscount) Palette.rose else Palette.accentStrong,
            maxLines = 1,
            style = displayFont(
                size = FontSize.Body,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun Token(
    label: String,
    value: String,
    isSelected: Boolean,
    onSelect: () -> Unit,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(8.dp))
    val fill = if (isSelected) Palette.accent.opacity(Emphasis.Subtle) else Color.Transparent

    Row(
        modifier = Modifier
            .clip(shape)
            .background(fill)
            .clickable(onClick = onSelect)
            .padding(8.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            color = if (isSelected) Palette.accent else Palette.subtext,
            style = textFont(size = FontSize.Caption),
        )

        Text(
            text = value,
            color = if (isSelected) Palette.accentStrong else Palette.text,
            maxLines = 1,
            style = displayFont(
                size = FontSize.Body,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun Operator(text: String) {
    Text(
        text = text,
        color = Palette.subtext,
        style = textFont(size = FontSize.Body),
    )
}

@Composable
private fun Chip(
    title: String,
    isSelected: Boolean,
    onSelect: () -> Unit,
) {
    val fill = if (isSelected) Palette.accent.opacity(Emphasis.Soft) else Color.Transparent
    val rim = if (isSelected) Palette.accent else Palette.accent.opacity(Emphasis.Muted)

    Box(
        modifier = Modifier
            .height(30.dp)
            .clip(CircleShape)
            .background(fill)
            .border(
                width = 1.dp,
                color = rim,
                shape = CircleShape,
            ).clickable(onClick = onSelect)
            .padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            color = if (isSelected) Palette.accentStrong else Palette.text,
            maxLines = 1,
            style = textFont(
                size = FontSize.Caption,
                weight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            ),
        )
    }
}

@Composable
private fun Rule() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(Palette.paperEdge),
    )
}

@Composable
private fun RingButton(
    icon: Int,
    isProminent: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(if (isProminent) Palette.accent else Color.Transparent)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Muted),
                shape = CircleShape,
            ).clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(icon),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = if (isProminent) Palette.backgroundTop else Palette.subtext,
        )
    }
}

private const val REMOVED_NOTICE_MILLIS = 4_000L
