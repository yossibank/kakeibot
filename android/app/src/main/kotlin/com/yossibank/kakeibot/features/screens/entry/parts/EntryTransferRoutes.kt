package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.icon.IconImage
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.colorOf
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.TransferRoute
import com.yossibank.kakeibot.featuremodels.screens.entry.model.applyRoute
import com.yossibank.kakeibot.featuremodels.screens.entry.model.frequentRoutes
import com.yossibank.kakeibot.featuremodels.screens.entry.model.wallet
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText

@Composable
internal fun EntryTransferRoutes(model: EntryModel) {
    val routes = model.output.frequentRoutes

    if (routes.isEmpty()) {
        return
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        routes.forEach { route ->
            RouteChip(
                model = model,
                route = route,
            )
        }
    }
}

@Composable
internal fun PayOffButton(
    remaining: Long,
    onSelect: () -> Unit,
) {
    Row(
        modifier = Modifier
            .height(40.dp)
            .clip(CircleShape)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = CircleShape,
            ).clickable(onClick = onSelect)
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_check),
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = Palette.accent,
        )

        Text(
            text = "残り ${AmountText.text(remaining.toInt())} をまとめて返す",
            color = Palette.accent,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun RouteChip(
    model: EntryModel,
    route: TransferRoute,
) {
    val isApplied =
        model.state.form.walletId == route.walletId &&
            model.state.form.toWalletId == route.toWalletId

    val fill = if (isApplied) Palette.accent.opacity(Emphasis.Soft) else Color.Transparent
    val rim = if (isApplied) Palette.accent else Palette.accent.opacity(Emphasis.Muted)
    val style = textFont(size = FontSize.Caption)

    Row(
        modifier = Modifier
            .height(32.dp)
            .clip(CircleShape)
            .background(fill)
            .border(
                width = 1.dp,
                color = rim,
                shape = CircleShape,
            ).clickable { model.state.applyRoute(route) }
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = model.output.wallet(of = route.walletId)?.name ?: "",
            color = Palette.text,
            style = style,
        )

        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier.size(12.dp),
            tint = Palette.accent,
        )

        Text(
            text = model.output.wallet(of = route.toWalletId)?.name ?: "",
            color = Palette.text,
            style = style,
        )
    }
}
