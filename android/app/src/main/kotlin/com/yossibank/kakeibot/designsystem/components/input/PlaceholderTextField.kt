package com.yossibank.kakeibot.designsystem.components.input

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import com.yossibank.kakeibot.designsystem.theme.Palette

@Composable
fun PlaceholderTextField(
    value: String,
    onChange: (String) -> Unit,
    placeholder: String,
    style: TextStyle,
    modifier: Modifier = Modifier,
    color: Color = Palette.text,
    onDone: (() -> Unit)? = null,
) {
    val options = if (onDone != null) {
        KeyboardOptions(imeAction = ImeAction.Done)
    } else {
        KeyboardOptions.Default
    }

    BasicTextField(
        value = value,
        onValueChange = onChange,
        modifier = modifier,
        textStyle = style.copy(color = color),
        singleLine = true,
        keyboardOptions = options,
        keyboardActions = KeyboardActions(onDone = { onDone?.invoke() }),
        cursorBrush = SolidColor(Palette.accent),
        decorationBox = { field ->
            Box(propagateMinConstraints = true) {
                if (value.isEmpty()) {
                    Text(
                        text = placeholder,
                        color = Palette.hint,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        style = style,
                    )
                }

                field()
            }
        },
    )
}
