package com.yossibank.kakeibot.designsystem.components.entry

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
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
import com.yossibank.kakeibot.designsystem.components.layout.HorizontalFit
import com.yossibank.kakeibot.designsystem.components.tag.TagCard
import com.yossibank.kakeibot.designsystem.components.tag.TagCardSize
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryRowItem
import androidx.compose.material3.Icon as SymbolIcon

@Composable
fun EntryRow(
    icon: Icon?,
    title: String,
    detail: String?,
    amount: Int,
    type: Entry.Kind,
    modifier: Modifier = Modifier,
    tag: String? = null,
    route: EntryRowItem.Route? = null,
    memo: String? = null,
    isRecurring: Boolean = false,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = Metrics.rowMinHeight),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        LeadingIcon(
            icon = icon,
            type = type,
        )

        Texts(
            title = title,
            detail = detail,
            tag = tag,
            route = route,
            memo = memo,
            isRecurring = isRecurring,
        )

        AmountText(
            amount = amount,
            style = displayFont(size = FontSize.Body),
            type = type,
        )
    }
}

@Composable
private fun LeadingIcon(
    icon: Icon?,
    type: Entry.Kind,
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
}

@Composable
private fun RowScope.Texts(
    title: String,
    detail: String?,
    tag: String?,
    route: EntryRowItem.Route?,
    memo: String?,
    isRecurring: Boolean,
) {
    val showsMemo = tag != null || detail == null || route != null

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

        Details(
            tag = tag,
            detail = detail,
            memo = memo.takeIf { route == null },
        )

        if (route != null) {
            EntryRoute(
                source = route.source,
                destination = route.destination,
            )
        }

        if (memo != null && showsMemo) {
            EntryMemo(text = memo)
        }
    }
}

@Composable
private fun Details(
    tag: String?,
    detail: String?,
    memo: String?,
) {
    if (tag != null) {
        HorizontalFit(
            wide = {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    SmallTag(title = tag)

                    Note(text = detail)
                }
            },
            narrow = {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Note(text = detail)

                    SmallTag(title = tag)
                }
            },
        )
    } else if (detail != null && memo != null) {
        HorizontalFit(
            wide = {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Note(text = detail)

                    EntryMemo(text = memo)
                }
            },
            narrow = {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Note(text = detail)

                    EntryMemo(text = memo)
                }
            },
        )
    } else {
        Note(text = detail)
    }
}

@Composable
private fun SmallTag(title: String) {
    TagCard(
        title = title,
        size = TagCardSize.Small,
    )
}

@Composable
private fun Note(text: String?) {
    if (text.isNullOrEmpty()) {
        return
    }

    FittedText(
        text = text,
        color = Palette.subtext,
        style = textFont(style = FontTextStyle.Caption),
    )
}
