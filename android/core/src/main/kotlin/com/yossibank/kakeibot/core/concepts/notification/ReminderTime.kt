package com.yossibank.kakeibot.core.concepts.notification

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

@ConsistentCopyVisibility
@Serializable(with = ReminderTimeSerializer::class)
data class ReminderTime private constructor(
    val hour: Int,
    val minute: Int,
) : Comparable<ReminderTime> {
    override fun compareTo(other: ReminderTime): Int = compareValuesBy(
        this,
        other,
        { it.hour },
        { it.minute },
    )

    override fun toString(): String {
        val hour = if (hour < 10) "0$hour" else "$hour"
        val minute = if (minute < 10) "0$minute" else "$minute"

        return "$hour:$minute"
    }

    companion object {
        val morning = ReminderTime(
            hour = 9,
            minute = 0,
        )

        val evening = ReminderTime(
            hour = 21,
            minute = 0,
        )

        fun of(
            hour: Int,
            minute: Int,
        ): ReminderTime? {
            if (hour !in 0..23 || minute !in 0..59) {
                return null
            }

            return ReminderTime(
                hour = hour,
                minute = minute,
            )
        }

        fun parse(text: String): ReminderTime? {
            val parts = text.split(":").filter { it.isNotEmpty() }

            if (parts.size != 2 || parts.any { it.length != 2 }) {
                return null
            }

            val hour = number(parts[0]) ?: return null
            val minute = number(parts[1]) ?: return null

            return of(
                hour = hour,
                minute = minute,
            )
        }

        private fun number(text: String): Int? {
            val sign = text.first()
            val digits = if (sign == '+' || sign == '-') text.drop(1) else text

            if (digits.isEmpty() || digits.any { it !in '0'..'9' }) {
                return null
            }

            val value = digits.toInt()

            return if (sign == '-') -value else value
        }
    }
}

object ReminderTimeSerializer : KSerializer<ReminderTime> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "ReminderTime",
        PrimitiveKind.STRING,
    )

    override fun serialize(
        encoder: Encoder,
        value: ReminderTime,
    ) {
        encoder.encodeString(value.toString())
    }

    override fun deserialize(decoder: Decoder): ReminderTime {
        val text = decoder.decodeString()

        return ReminderTime.parse(text) ?: throw SerializationException("Invalid time: $text")
    }
}
