package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.core.SpringSpec
import androidx.compose.animation.core.VisibilityThreshold
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.designsystem.components.date.MonthCalendar
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.row.FeeChoiceRow
import com.yossibank.kakeibot.designsystem.components.tag.TagLine
import com.yossibank.kakeibot.designsystem.components.tag.TagLineItem
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.amount
import com.yossibank.kakeibot.featuremodels.screens.entry.model.fee
import com.yossibank.kakeibot.featuremodels.screens.entry.model.feeChoices
import com.yossibank.kakeibot.featuremodels.screens.entry.model.select
import com.yossibank.kakeibot.featuremodels.screens.entry.model.selectDestination
import com.yossibank.kakeibot.featuremodels.screens.entry.model.showsItems
import com.yossibank.kakeibot.featuremodels.screens.entry.model.tags
import com.yossibank.kakeibot.featuremodels.screens.entry.model.toggleTag
import com.yossibank.kakeibot.featuremodels.screens.entry.model.walletTitle

@Composable
fun EntryDeck(
    model: EntryModel,
    onOpenItems: () -> Unit,
    onSaveTemplate: () -> Unit,
    modifier: Modifier = Modifier,
) {
    key(model.state.form.type) {
        AnimatedContent(
            targetState = model.state.field,
            modifier = modifier,
            transitionSpec = { deckTransition(isForward = model.state.isForward) },
            label = "EntryDeck",
        ) { field ->
            DeckFace(
                model = model,
                field = field,
                onOpenItems = onOpenItems,
                onSaveTemplate = onSaveTemplate,
            )
        }
    }
}

@Composable
private fun DeckFace(
    model: EntryModel,
    field: EntryModel.Field,
    onOpenItems: () -> Unit,
    onSaveTemplate: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        DeckHeader(
            model = model,
            field = field,
            onOpenItems = onOpenItems,
        )

        Box(modifier = Modifier.weight(1f)) {
            DeckContent(
                model = model,
                field = field,
                onSaveTemplate = onSaveTemplate,
            )
        }
    }
}

@Composable
private fun DeckHeader(
    model: EntryModel,
    field: EntryModel.Field,
    onOpenItems: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(28.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        DeckTitle(
            text = when (field) {
                EntryModel.Field.Category -> "カテゴリを選ぶ"
                EntryModel.Field.Wallet -> "${model.output.walletTitle}を選ぶ"
                EntryModel.Field.ToWallet -> "振替先を選ぶ"
                EntryModel.Field.Date -> "日付を選ぶ"
                EntryModel.Field.Amount -> "金額を入力"
                EntryModel.Field.Fee -> "手数料を入力"
                EntryModel.Field.Transfer -> "振替元と振替先"
            },
        )

        Spacer(modifier = Modifier.weight(1f))

        if (field == EntryModel.Field.Amount && model.output.showsItems) {
            ItemPill(onOpen = onOpenItems)
        }
    }
}

@Composable
private fun DeckContent(
    model: EntryModel,
    field: EntryModel.Field,
    onSaveTemplate: () -> Unit,
) {
    when (field) {
        EntryModel.Field.Category -> CategoryArea(
            model = model,
            onSaveTemplate = onSaveTemplate,
        )

        EntryModel.Field.Wallet -> WalletList(
            model = model,
            selection = model.state.form.walletId,
            onSelect = { model.select(wallet = it) },
        )

        EntryModel.Field.ToWallet -> WalletList(
            model = model,
            selection = model.state.form.toWalletId,
            onSelect = model.state::selectDestination,
        )

        EntryModel.Field.Date -> DateCalendar(model = model)

        EntryModel.Field.Amount -> AmountKeypad(
            calculator = model.state.calculator,
            onKey = model.state::press,
        )

        EntryModel.Field.Transfer -> EntryTransferArea(model = model)

        EntryModel.Field.Fee -> FeeDeck(model = model)
    }
}

@Composable
private fun FeeDeck(model: EntryModel) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        FeeChoiceRow(
            choices = model.output.feeChoices,
            selection = model.output.fee,
            onSelect = model.state::setFee,
        )

        Box(modifier = Modifier.weight(1f)) {
            AmountKeypad(
                calculator = model.state.feeCalculator,
                onKey = model.state::press,
            )
        }
    }
}

@Composable
private fun ItemPill(onOpen: () -> Unit) {
    Row(
        modifier = Modifier
            .height(28.dp)
            .clip(CircleShape)
            .background(Palette.accent.opacity(Emphasis.Subtle))
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = CircleShape,
            ).clickable(onClick = onOpen)
            .padding(
                start = 4.dp,
                end = 12.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(20.dp)
                .clip(CircleShape)
                .background(Palette.accent),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                painter = painterResource(R.drawable.ic_plus),
                contentDescription = null,
                modifier = Modifier.size(14.dp),
                tint = Palette.backgroundTop,
            )
        }

        Text(
            text = "品目に分ける",
            color = Palette.accent,
            style = textFont(
                size = FontSize.Caption,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun DeckTitle(text: String) {
    Text(
        text = text,
        color = Palette.subtext,
        style = textFont(
            size = FontSize.Caption,
            weight = FontWeight.SemiBold,
        ),
    )
}

@Composable
private fun AmountKeypad(
    calculator: AmountCalculator,
    onKey: (AmountCalculator.Key) -> Unit,
) {
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val spacing = 8.dp * (KEY_ROWS - 1)
        val height = ((maxHeight - spacing) / KEY_ROWS).coerceIn(minKeyHeight, maxKeyHeight)

        Keypad(
            calculator = calculator,
            onKey = onKey,
            keyHeight = height,
        )
    }
}

@Composable
private fun CategoryArea(
    model: EntryModel,
    onSaveTemplate: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        CategoryGrid(
            model = model,
            modifier = Modifier.weight(1f),
        )

        val tags = model.output.tags

        if (tags.isNotEmpty()) {
            TagLine(
                tags = tags.map { TagLineItem(id = it.id, name = it.name) },
                selection = model.state.form.tagId,
                onSelect = model.state::toggleTag,
            )
        }

        if (model.output.amount > 0) {
            SaveTemplateChip(onSelect = onSaveTemplate)
        }
    }
}

@Composable
private fun SaveTemplateChip(onSelect: () -> Unit) {
    val rim = Palette.accent.opacity(Emphasis.Medium)

    Row(
        modifier = Modifier
            .height(32.dp)
            .clip(CircleShape)
            .drawBehind {
                drawRoundRect(
                    color = rim,
                    cornerRadius = CornerRadius(size.height / 2),
                    style = Stroke(
                        width = 1.dp.toPx(),
                        pathEffect = PathEffect.dashPathEffect(
                            floatArrayOf(4.dp.toPx(), 3.dp.toPx()),
                        ),
                    ),
                )
            }.clickable(onClick = onSelect)
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_plus),
            contentDescription = null,
            modifier = Modifier.size(14.dp),
            tint = Palette.accent,
        )

        Text(
            text = "今の入力を保存",
            color = Palette.accent,
            style = textFont(
                size = FontSize.Caption,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun DateCalendar(model: EntryModel) {
    MonthCalendar(
        selection = model.state.form.date,
        today = model.state.today,
        onSelect = model.state::select,
    )
}

private fun deckTransition(isForward: Boolean): ContentTransform {
    val entering = if (isForward) 1 else -1
    val slide = snappy(IntOffset.VisibilityThreshold)
    val fade = snappy<Float>()

    val enter = slideInHorizontally(animationSpec = slide) { it * entering } +
        fadeIn(animationSpec = fade)

    val exit = slideOutHorizontally(animationSpec = slide) { -it * entering } +
        fadeOut(animationSpec = fade)

    return enter togetherWith exit
}

private fun <T> snappy(visibilityThreshold: T? = null): SpringSpec<T> = spring(
    dampingRatio = SNAPPY_DAMPING,
    stiffness = SNAPPY_STIFFNESS,
    visibilityThreshold = visibilityThreshold,
)

private const val KEY_ROWS = 5
private const val SNAPPY_DAMPING = 0.85f
private const val SNAPPY_STIFFNESS = 158f

private val minKeyHeight: Dp = 36.dp
private val maxKeyHeight: Dp = 72.dp
