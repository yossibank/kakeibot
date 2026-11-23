package com.yossibank.kakeibot.designsystem.components.text

import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import com.yossibank.kakeibot.designsystem.theme.TextScale

@Composable
fun FittedText(
    text: String,
    style: TextStyle,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
    textAlign: TextAlign? = null,
    floor: Double = TextScale.FLOOR,
) {
    val sizes = TextAutoSize.StepBased(
        minFontSize = style.fontSize * floor,
        maxFontSize = style.fontSize,
        stepSize = STEP.sp,
    )

    Text(
        text = text,
        modifier = modifier,
        color = color,
        textAlign = textAlign,
        overflow = TextOverflow.Ellipsis,
        softWrap = false,
        maxLines = 1,
        autoSize = sizes,
        style = style,
    )
}

private const val STEP = 0.5f
