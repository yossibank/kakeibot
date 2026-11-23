package com.yossibank.kakeibot.core.concepts.icon

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

object GlyphSerializer : KSerializer<Icon.Glyph> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "Icon.Glyph",
        PrimitiveKind.STRING,
    )

    override fun serialize(
        encoder: Encoder,
        value: Icon.Glyph,
    ) {
        encoder.encodeString(value.rawValue)
    }

    override fun deserialize(decoder: Decoder): Icon.Glyph =
        Icon.Glyph.known(decoder.decodeString())
}
