package com.yossibank.kakeibot.features.shared.entrylist

import androidx.compose.foundation.clickable
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.yossibank.kakeibot.designsystem.components.entry.EntryRow
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryRowItem

@Composable
fun EntryItemRow(
    item: EntryRowItem,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
) {
    EntryRow(
        icon = item.icon,
        title = item.title,
        detail = item.place,
        amount = item.amount,
        type = item.type,
        modifier = modifier.clickable(onClick = onOpen),
        memo = item.memo,
        isRecurring = item.isRecurring,
    )
}
