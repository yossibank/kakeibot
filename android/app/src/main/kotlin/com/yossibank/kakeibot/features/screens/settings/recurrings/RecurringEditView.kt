package com.yossibank.kakeibot.features.screens.settings.recurrings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.modal.DeleteDialog
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.parts.EntryTypeSwitch
import com.yossibank.kakeibot.features.shared.settingsparts.ChoiceChip
import com.yossibank.kakeibot.features.shared.settingsparts.RoundIconButton
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHeader
import com.yossibank.kakeibot.store.database.AppDatabase
import kotlinx.coroutines.launch

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun RecurringEditView(
    database: AppDatabase,
    today: LocalDate,
    editing: Recurring?,
    onClose: () -> Unit,
) {
    val model = remember(database, editing) {
        RecurringEditModel(
            database = database,
            today = today,
            editing = editing,
        )
    }

    val scope = rememberCoroutineScope()
    var isConfirmingDelete by remember { mutableStateOf(false) }

    LaunchedEffect(model) {
        model.load()
    }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SettingsHeader(
            title = if (model.isEditing) "固定費を編集" else "固定費を追加",
            isRoot = false,
            onBack = onClose,
        ) {
            if (model.isEditing) {
                RoundIconButton(
                    icon = R.drawable.ic_trash,
                    onSelect = { isConfirmingDelete = true },
                )
            }
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            EntryTypeSwitch(
                selection = model.type,
                onSelect = model::select,
                hasTransfer = false,
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .card(),
            ) {
                NameField(model = model)

                SettingsDivider()

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(
                            horizontal = 16.dp,
                            vertical = 8.dp,
                        ),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "金額",
                        modifier = Modifier.weight(1f),
                        color = Palette.subtext,
                        style = textFont(style = FontTextStyle.Subheadline),
                    )

                    AmountText(
                        amount = model.calculator.amount,
                        style = displayFont(
                            size = FontSize.LargeTitle,
                            weight = FontWeight.Bold,
                        ),
                        color = if (model.calculator.amount >
                            0
                        ) {
                            Palette.accentStrong
                        } else {
                            Palette.hint
                        },
                    )
                }
            }

            SettingsCaption(text = "いつ")

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .card()
                    .padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = model.scheduleText,
                        modifier = Modifier.weight(1f),
                        color = Palette.text,
                        style = textFont(style = FontTextStyle.Body),
                    )

                    SegmentSwitch(
                        selection = model.frequency,
                        options = frequencies,
                        onSelect = { model.frequency = it },
                    )
                }

                if (model.frequency == Recurring.Frequency.yearly) {
                    Stepper(
                        title = "月",
                        value = "${model.month} 月",
                        onMove = model::moveMonth,
                    )
                }

                Stepper(
                    title = "日",
                    value = if (model.day == 31) "末日" else "${model.day} 日",
                    onMove = model::moveDay,
                )
            }

            SettingsCaption(text = "カテゴリ")

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                model.categories.forEach { category ->
                    ChoiceChip(
                        title = category.name,
                        isSelected = category.id == model.categoryId,
                        onSelect = { model.categoryId = category.id },
                    ) {
                        IconTile(
                            icon = model.icon(of = category.iconId),
                            size = 24.dp,
                        )
                    }
                }
            }

            SettingsCaption(text = "口座")

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                model.wallets.forEach { wallet ->
                    ChoiceChip(
                        title = wallet.name,
                        isSelected = wallet.id == model.walletId,
                        onSelect = { model.walletId = wallet.id },
                    ) {
                        IconTile(
                            icon = model.icon(of = wallet.iconId),
                            size = 24.dp,
                        )
                    }
                }
            }
        }

        Keypad(
            calculator = model.calculator,
            onKey = model::press,
            keyHeight = 42.dp,
        )

        Text(
            text = model.message,
            color = Palette.rose,
            maxLines = 1,
            style = textFont(size = FontSize.Caption),
        )

        SaveBar(
            title = "保存する",
            onSave = {
                scope.launch {
                    if (model.save()) {
                        onClose()
                    }
                }
            },
        )
    }

    if (isConfirmingDelete) {
        DeleteDialog(
            title = "この固定費を削除しますか",
            message = "これまでに作った記録は残ります",
            onConfirm = {
                isConfirmingDelete = false

                scope.launch {
                    if (model.delete()) {
                        onClose()
                    }
                }
            },
            onDismiss = { isConfirmingDelete = false },
        )
    }
}

@Composable
private fun NameField(model: RecurringEditModel) {
    val style = textFont(style = FontTextStyle.Body)

    BasicTextField(
        value = model.memo,
        onValueChange = { model.memo = it },
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        textStyle = style.copy(color = Palette.text),
        singleLine = true,
        cursorBrush = SolidColor(Palette.accent),
        decorationBox = { field ->
            if (model.memo.isEmpty()) {
                Text(
                    text = "名前（家賃、サブスクなど）",
                    color = Palette.hint,
                    style = style,
                )
            }

            field()
        },
    )
}

@Composable
private fun Stepper(
    title: String,
    value: String,
    onMove: (Int) -> Unit,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            modifier = Modifier.weight(1f),
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Subheadline),
        )

        RoundIconButton(
            icon = R.drawable.ic_chevron_right,
            rotation = 180f,
            onSelect = { onMove(-1) },
        )

        Text(
            text = value,
            modifier = Modifier.widthIn(min = 64.dp),
            color = Palette.accentStrong,
            textAlign = TextAlign.Center,
            style = displayFont(size = FontSize.Body),
        )

        RoundIconButton(
            icon = R.drawable.ic_chevron_right,
            onSelect = { onMove(1) },
        )
    }
}

private val frequencies = listOf(
    Recurring.Frequency.monthly to "毎月",
    Recurring.Frequency.yearly to "毎年",
)
