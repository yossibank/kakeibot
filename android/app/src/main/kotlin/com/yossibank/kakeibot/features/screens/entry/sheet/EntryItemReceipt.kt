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
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.input.PlaceholderTextField
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryItemEditor
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.hasItemAdjustment
import com.yossibank.kakeibot.featuremodels.screens.entry.model.itemCount
import com.yossibank.kakeibot.featuremodels.screens.entry.model.itemTotals
import com.yossibank.kakeibot.featuremodels.screens.entry.model.setTaxIncluded
import com.yossibank.kakeibot.featuremodels.screens.entry.model.store
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText
import kotlinx.coroutines.delay

@Composable
fun EntryItemReceipt(
    model: EntryModel,
    editor: EntryItemEditor,
) {
    val totals = model.output.itemTotals
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
            val date = model.state.form.date

            Text(
                text = "${date.year}/${PeriodText.weekdayDate(date)}",
                color = Palette.subtext,
                style = textFont(size = FontSize.Caption),
            )

            StoreField(model = model)
        }

        Hairline(color = Palette.paperEdge)

        if (model.state.form.items.isEmpty()) {
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
                model.state.form.items.forEachIndexed { index, item ->
                    key(index, item) {
                        ItemRow(
                            item = item,
                            isEditing = editor.isOpen && editor.editingIndex == index,
                            showsRate = model.state.form.items.map { it.taxRate }.toSet().size > 1,
                            onSelect = { editor.edit(index, item) },
                            onRemove = { editor.remove(model, index) },
                        )
                    }
                }
            }
        }

        Hairline(color = Palette.paperEdge)

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
                    selection = model.state.form.taxIncluded,
                    options = listOf(false to "外税", true to "内税"),
                    onSelect = model::setTaxIncluded,
                )
            }

            totals.taxes.forEach { tax ->
                val title = if (model.state.form.taxIncluded) "内消費税" else "消費税"

                SummaryLine(
                    title = "${tax.rate.rawValue}%対象 ${AmountText.text(tax.base.toInt())}",
                    amount = null,
                    detail = "$title ${AmountText.text(tax.amount.toInt())}",
                )
            }
        }

        if (model.output.hasItemAdjustment) {
            AdjustmentLine(model = model)
        }

        Hairline(color = Palette.paperEdge)

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

            FittedText(
                text = AmountText.text(model.output.amount),
                color = Palette.accentStrong,
                style = displayFont(
                    size = FontSize.Display,
                    weight = FontWeight.Bold,
                ),
            )
        }

        if (model.state.form.items.isNotEmpty()) {
            Row {
                Text(
                    text = "お買上点数",
                    modifier = Modifier.weight(1f),
                    color = Palette.subtext,
                    style = textFont(size = FontSize.Caption),
                )

                Text(
                    text = "${model.output.itemCount}点",
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
    ).copy(textAlign = TextAlign.Center)

    PlaceholderTextField(
        value = model.state.store,
        onChange = { model.state.store = it },
        placeholder = "店名を入れる",
        style = style,
        modifier = Modifier.fillMaxWidth(),
    )
}
