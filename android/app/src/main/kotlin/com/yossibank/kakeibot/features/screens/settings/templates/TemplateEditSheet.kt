package com.yossibank.kakeibot.features.screens.settings.templates

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.billShiftTitles
import com.yossibank.kakeibot.designsystem.components.button.PrimaryButton
import com.yossibank.kakeibot.designsystem.components.icon.IconImage
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.input.PlaceholderTextField
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.tag.TagLine
import com.yossibank.kakeibot.designsystem.components.tag.TagLineItem
import com.yossibank.kakeibot.designsystem.components.template.TemplateCard
import com.yossibank.kakeibot.designsystem.components.template.TemplateCardAmount
import com.yossibank.kakeibot.designsystem.components.template.TemplateCardSize
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.templates.TemplateEditModel
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.features.shared.model.OnOutcome
import com.yossibank.kakeibot.features.shared.settingsparts.input.ChoiceChip
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsHeader
import com.yossibank.kakeibot.store.database.AppDatabase

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TemplateEditSheet(
    database: AppDatabase,
    draft: EntryTemplateDraft,
    onSave: (EntryTemplate) -> Unit,
    onClose: () -> Unit,
) {
    val model = remember(database, draft) {
        TemplateEditModel(
            database = database,
            clock = ScreenClock.system,
            draft = draft,
        )
    }

    val focus = LocalFocusManager.current

    LaunchedEffect(model) {
        model.load()
    }

    model.state.task.Timer()

    OnOutcome(model.state.outcome) { outcome ->
        outcome.saved?.let(onSave)
    }

    BackHandler(onBack = onClose)

    SettingsFrame(
        title = "テンプレートを追加",
        isRoot = true,
        onBack = onClose,
        followsKeyboard = true,
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                TemplateCard(
                    icon = model.output.category?.let { model.output.icon(of = it.iconId) },
                    detail = model.output.detail,
                    size = TemplateCardSize.Large,
                    name = {
                        PlaceholderTextField(
                            value = model.state.form.name,
                            onChange = { name -> model.state.update { copy(name = name) } },
                            placeholder = "名前を入れる",
                            style = displayFont(
                                size = FontSize.Headline,
                                weight = FontWeight.Medium,
                            ),
                            modifier = Modifier.fillMaxWidth(),
                            color = Palette.accentStrong,
                            onDone = focus::clearFocus,
                        )
                    },
                    amount = {
                        TemplateCardAmount(
                            amount = model.output.amount,
                            size = TemplateCardSize.Large,
                        )
                    },
                )

                PreviewNote(text = "ホームでは、このカードで並びます")
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .card(),
            ) {
                PlaceholderTextField(
                    value = model.state.form.memo,
                    onChange = { memo -> model.state.update { copy(memo = memo) } },
                    placeholder = "メモを書く",
                    style = textFont(style = FontTextStyle.Body),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    onDone = focus::clearFocus,
                )
            }

            SettingsCaption(text = "金額を空にすると、使うときに入れられます。")

            SettingsCaption(text = "カテゴリ")

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                model.output.categories.forEach { category ->
                    ChoiceChip(
                        title = category.name,
                        isSelected = category.id == model.state.form.categoryId,
                        onSelect = { model.state.select(category) },
                    ) {
                        IconTile(
                            icon = model.output.icon(of = category.iconId),
                            size = 24.dp,
                        )
                    }
                }
            }

            val tags = model.output.tags

            if (tags.isNotEmpty()) {
                SettingsCaption(text = "タグ")

                TagLine(
                    tags = tags.map { TagLineItem(id = it.id, name = it.name) },
                    selection = model.state.form.tagId,
                    onSelect = model.state::toggleTag,
                )
            }

            SettingsCaption(text = model.output.walletTitle)

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                model.output.wallets.forEach { wallet ->
                    ChoiceChip(
                        title = wallet.name,
                        isSelected = wallet.id == model.state.form.walletId,
                        onSelect = { model.state.select(wallet) },
                    ) {
                        IconTile(
                            icon = model.output.icon(of = wallet.iconId),
                            size = 24.dp,
                        )
                    }
                }
            }

            if (model.output.billRecurring != null) {
                SettingsCaption(text = "請求")

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Recurring.billShiftTitles.forEachIndexed { index, title ->
                        ChoiceChip(
                            title = title,
                            isSelected = model.state.form.billShift == index,
                            onSelect = { model.state.update { copy(billShift = index) } },
                        )
                    }
                }

                SettingsCaption(
                    text = billNotes[model.state.form.billShift.coerceIn(billNotes.indices)],
                )
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                CapsulePreview(model = model)

                PreviewNote(text = "入力シートでは、この形で並びます")
            }
        }

        Keypad(
            calculator = model.state.calculator,
            onKey = { key ->
                focus.clearFocus()
                model.state.press(key)
            },
            keyHeight = 42.dp,
        )

        FittedText(
            text = model.state.task.message,
            modifier = Modifier.clickable(onClick = model.state.task::clear),
            color = Palette.rose,
            style = textFont(size = FontSize.Caption),
        )

        PrimaryButton(
            title = model.output.saveTitle,
            onClick = {
                focus.clearFocus()
                model.perform { it.save() }
            },
            modifier = Modifier.fillMaxWidth(),
            isEnabled = model.output.canSave,
        )
    }
}

@Composable
private fun CapsulePreview(model: TemplateEditModel) {
    Row(
        modifier = Modifier
            .height(30.dp)
            .clip(CircleShape)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Muted),
                shape = CircleShape,
            ).padding(
                start = 8.dp,
                end = 12.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CompositionLocalProvider(LocalContentColor provides Palette.accent) {
            IconImage(
                icon = model.output.category?.let { model.output.icon(of = it.iconId) },
                size = 12.dp,
            )
        }

        FittedText(
            text = model.state.form.name.ifEmpty { "名前" },
            color = Palette.text,
            modifier = Modifier.weight(1f, fill = false),
            style = textFont(size = FontSize.Caption),
        )

        FittedText(
            text = model.output.amount?.let { AmountText.text(it) } ?: "毎回入れる",
            color = Palette.accentStrong,
            style = displayFont(size = FontSize.Caption),
        )
    }
}

@Composable
private fun PreviewNote(text: String) {
    Text(
        text = text,
        color = Palette.subtext,
        style = textFont(size = FontSize.Caption),
    )
}

private val billNotes = listOf(
    "使った日の、いつもの引き落としに入れます",
    "使った日から 1 回あとの引き落としに回します",
    "使った日から 2 回あとの引き落としに回します",
)
