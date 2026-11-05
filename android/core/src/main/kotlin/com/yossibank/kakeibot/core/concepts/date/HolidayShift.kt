package com.yossibank.kakeibot.core.concepts.date

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

@Serializable(with = HolidayShiftSerializer::class)
enum class HolidayShift(
    val rawValue: String,
) {
    none("none"),
    previous("previous"),
    next("next"),
    ;

    fun apply(to: LocalDate): LocalDate {
        val step = when (this) {
            none -> 0
            previous -> -1
            next -> 1
        }

        if (step == 0) {
            return to
        }

        var shifted = to

        while (Holiday.isDayOff(shifted)) {
            shifted = shifted.adding(days = step)
        }

        return shifted
    }

    companion object {
        fun of(rawValue: String): HolidayShift? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

object HolidayShiftSerializer : KSerializer<HolidayShift> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "HolidayShift",
        PrimitiveKind.STRING,
    )

    override fun serialize(
        encoder: Encoder,
        value: HolidayShift,
    ) {
        encoder.encodeString(value.rawValue)
    }

    override fun deserialize(decoder: Decoder): HolidayShift {
        val text = decoder.decodeString()

        return HolidayShift.of(text) ?: throw SerializationException("Invalid holiday shift: $text")
    }
}
