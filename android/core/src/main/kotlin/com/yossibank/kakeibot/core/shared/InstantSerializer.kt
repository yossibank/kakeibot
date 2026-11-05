package com.yossibank.kakeibot.core.shared

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.time.DateTimeException
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.ResolverStyle
import java.time.temporal.ChronoUnit

object InstantSerializer : KSerializer<Instant> {
    private val writer = DateTimeFormatter
        .ofPattern("uuuu-MM-dd'T'HH:mm:ssXXX")
        .withZone(ZoneOffset.UTC)

    private val reader = DateTimeFormatter
        .ofPattern("uuuu-MM-dd'T'HH:mm:ss[XXX][XX]")
        .withResolverStyle(ResolverStyle.STRICT)

    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "Instant",
        PrimitiveKind.STRING,
    )

    override fun serialize(
        encoder: Encoder,
        value: Instant,
    ) {
        encoder.encodeString(format(value))
    }

    override fun deserialize(decoder: Decoder): Instant {
        val text = decoder.decodeString()

        return parse(text) ?: throw SerializationException("Invalid date: $text")
    }

    fun format(instant: Instant): String = writer.format(instant.truncatedTo(ChronoUnit.SECONDS))

    fun parse(text: String): Instant? = try {
        reader.parse(text, Instant::from)
    } catch (_: DateTimeException) {
        null
    }
}
