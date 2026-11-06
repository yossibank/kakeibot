package com.yossibank.kakeibot.store.records.protocols

import com.yossibank.kakeibot.core.shared.InstantSerializer
import java.time.DateTimeException
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeFormatterBuilder
import java.time.format.ResolverStyle
import java.time.temporal.ChronoField

private val fractionalStyle: DateTimeFormatter = DateTimeFormatterBuilder()
    .appendPattern("uuuu-MM-dd'T'HH:mm:ss")
    .appendFraction(
        ChronoField.NANO_OF_SECOND,
        1,
        9,
        true,
    )
    .appendPattern("[XXX][XX]")
    .toFormatter()
    .withResolverStyle(ResolverStyle.STRICT)

val Instant.storedValue: String
    get() = InstantSerializer.format(this)

fun storedInstant(text: String): Instant? = InstantSerializer.parse(text) ?: fractional(text)

private fun fractional(text: String): Instant? = try {
    fractionalStyle.parse(text, Instant::from)
} catch (_: DateTimeException) {
    null
}

class RecordDecodingException(
    record: Any,
) : Exception("Unreadable record: $record")

fun <Record : Any, Value : Any> Record.decoded(convert: (Record) -> Value?): Value =
    convert(this) ?: throw RecordDecodingException(this)
