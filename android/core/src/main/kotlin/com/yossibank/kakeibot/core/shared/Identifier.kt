package com.yossibank.kakeibot.core.shared

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.util.UUID

data class Identifier<Owner>(
    val uuid: UUID = UUID.randomUUID(),
) {
    override fun toString(): String = uuid.toString().lowercase()

    companion object {
        private val pattern = Regex("[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}")

        fun <Owner> parse(text: String): Identifier<Owner>? {
            if (!pattern.matches(text)) {
                return null
            }

            return Identifier(UUID.fromString(text))
        }
    }
}

class IdentifierSerializer<Owner> : KSerializer<Identifier<Owner>> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "Identifier",
        PrimitiveKind.STRING,
    )

    override fun serialize(
        encoder: Encoder,
        value: Identifier<Owner>,
    ) {
        encoder.encodeString(value.toString())
    }

    override fun deserialize(decoder: Decoder): Identifier<Owner> {
        val text = decoder.decodeString()

        return Identifier.parse(text) ?: throw SerializationException("Invalid identifier: $text")
    }
}
