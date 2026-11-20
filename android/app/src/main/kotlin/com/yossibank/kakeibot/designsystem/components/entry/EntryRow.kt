package com.yossibank.kakeibot.designsystem.components.entry

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import androidx.compose.material3.Icon as SymbolIcon

@Composable
fun EntryRow(
    icon: Icon?,
    title: String,
    detail: String?,
    amount: Int,
    type: Entry.Kind,
    modifier: Modifier = Modifier,
    memo: String? = null,
    isRecurring: Boolean = false,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            IconTile(
                icon = icon,
                size = 28.dp,
            )
        } else if (type == Entry.Kind.transfer) {
            SymbolIcon(
                painter = painterResource(R.drawable.ic_swap),
                contentDescription = null,
                modifier = Modifier
                    .size(28.dp)
                    .padding(4.dp),
                tint = Palette.accent,
            )
        } else {
            Spacer(modifier = Modifier.size(28.dp))
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .padding(vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = title,
                    color = Palette.text,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    style = textFont(style = FontTextStyle.Subheadline),
                )

                if (isRecurring) {
                    SymbolIcon(
                        painter = painterResource(R.drawable.ic_repeat),
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = Palette.accent.opacity(Emphasis.Strong),
                    )
                }
            }

            val note = listOfNotNull(detail, memo).joinToString("｜")

            if (note.isNotEmpty()) {
                Text(
                    text = note,
                    color = Palette.subtext,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = textFont(style = FontTextStyle.Caption),
                )
            }
        }

        AmountText(
            amount = amount,
            style = displayFont(size = FontSize.Body),
            type = type,
        )
    }
}
