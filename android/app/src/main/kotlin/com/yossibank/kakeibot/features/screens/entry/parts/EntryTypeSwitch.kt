package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.apply
import com.yossibank.kakeibot.features.screens.entry.model.applyRecent
import com.yossibank.kakeibot.features.screens.entry.model.applyTransfer
import com.yossibank.kakeibot.features.screens.entry.model.categoryText
import com.yossibank.kakeibot.features.screens.entry.model.dateText
import com.yossibank.kakeibot.features.screens.entry.model.expressionText
import com.yossibank.kakeibot.features.screens.entry.model.newTemplateDraft
import com.yossibank.kakeibot.features.screens.entry.model.routeText
import com.yossibank.kakeibot.features.screens.entry.model.walletTitle
import com.yossibank.kakeibot.features.shared.entrylist.EntryText

private val types = listOf(
    Triple(Entry.Kind.expense, "支出", R.drawable.ic_arrow_upward),
    Triple(Entry.Kind.income, "収入", R.drawable.ic_arrow_downward),
    Triple(Entry.Kind.transfer, "振替", R.drawable.ic_swap),
)

@Composable
fun EntryTypeSwitch(
    selection: Entry.Kind,
    onSelect: (Entry.Kind) -> Unit,
    modifier: Modifier = Modifier,
    hasTransfer: Boolean = true,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(12.dp))
    val shown = types.filter { hasTransfer || it.first != Entry.Kind.transfer }

    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        shown.forEach { (type, title, icon) ->
            val isSelected = type == selection
            val color = if (isSelected) Palette.backgroundTop else Palette.subtext

            val fill = if (isSelected) {
                Brush.horizontalGradient(listOf(Palette.accentDeep, Palette.accent))
            } else {
                Palette.card
            }

            Row(
                modifier = Modifier
                    .height(36.dp)
                    .clip(shape)
                    .background(fill)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Muted),
                        shape = shape,
                    ).clickable { onSelect(type) }
                    .padding(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    painter = painterResource(icon),
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = color,
                )

                Text(
                    text = title,
                    color = color,
                    style = textFont(
                        size = FontSize.Body,
                        weight = FontWeight.SemiBold,
                    ),
                )
            }
        }
    }
}
