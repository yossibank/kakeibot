package com.yossibank.kakeibot.core.concepts.date

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

@Serializable(with = WeekdaySerializer::class)
enum class Weekday(
    val rawValue: String,
) {
    monday("monday"),
    tuesday("tuesday"),
    wednesday("wednesday"),
    thursday("thursday"),
    friday("friday"),
    saturday("saturday"),
    sunday("sunday"),
    ;

    internal val daysSinceMonday: Int
        get() = ordinal

    companion object {
        fun of(rawValue: String): Weekday? = entries.firstOrNull { it.rawValue == rawValue }

        fun week(startingOn: Weekday): List<Weekday> =
            (0 until 7).map { of(daysSinceMonday = startingOn.daysSinceMonday + it) }

        internal fun of(daysSinceMonday: Int): Weekday {
            val index = (daysSinceMonday % 7 + 7) % 7

            return entries[index]
        }
    }
}

object WeekdaySerializer : KSerializer<Weekday> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "Weekday",
        PrimitiveKind.STRING,
    )

    override fun serialize(
        encoder: Encoder,
        value: Weekday,
    ) {
        encoder.encodeString(value.rawValue)
    }

    override fun deserialize(decoder: Decoder): Weekday {
        val text = decoder.decodeString()

        return Weekday.of(text) ?: throw SerializationException("Invalid weekday: $text")
    }
}
