package com.yossibank.kakeibot.core.support

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import kotlinx.serialization.Serializable

@Serializable
data class FixtureMark(
    val kind: String,
    val value: String,
) {
    fun mark(): IconDraft.Mark = when (kind) {
        "glyph" -> IconDraft.Mark.Glyph(Icon.Glyph.of(value) ?: error("知らない glyph: $value"))
        "emoji" -> IconDraft.Mark.Emoji(value)
        "text" -> IconDraft.Mark.Text(value)
        else -> error("知らない mark の kind: $kind")
    }
}
