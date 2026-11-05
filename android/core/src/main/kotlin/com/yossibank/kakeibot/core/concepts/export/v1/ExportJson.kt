package com.yossibank.kakeibot.core.concepts.export.v1

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.shared.InstantSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.math.BigDecimal
import java.time.Instant

internal object ExportJson {
    private const val INDENT = "  "

    fun write(element: JsonElement): String {
        val out = StringBuilder()

        append(
            out = out,
            element = element,
            depth = 0,
        )

        return out.toString()
    }

    private fun append(
        out: StringBuilder,
        element: JsonElement,
        depth: Int,
    ) {
        when (element) {
            is JsonObject -> {
                val fields = element.entries.sortedBy { it.key }

                appendContainer(
                    out = out,
                    open = '{',
                    close = '}',
                    items = fields,
                    depth = depth,
                ) { field ->
                    appendString(
                        out = out,
                        text = field.key,
                    )

                    out.append(" : ")

                    append(
                        out = out,
                        element = field.value,
                        depth = depth + 1,
                    )
                }
            }

            is JsonArray -> appendContainer(
                out = out,
                open = '[',
                close = ']',
                items = element,
                depth = depth,
            ) { item ->
                append(
                    out = out,
                    element = item,
                    depth = depth + 1,
                )
            }

            is JsonNull -> out.append("null")

            is JsonPrimitive -> if (element.isString) {
                appendString(
                    out = out,
                    text = element.content,
                )
            } else {
                out.append(element.content)
            }
        }
    }

    private fun <T> appendContainer(
        out: StringBuilder,
        open: Char,
        close: Char,
        items: List<T>,
        depth: Int,
        appendItem: (T) -> Unit,
    ) {
        out.append(open)
        out.append('\n')

        for ((index, item) in items.withIndex()) {
            if (index > 0) {
                out.append(",\n")
            }

            out.append(INDENT.repeat(depth + 1))
            appendItem(item)
        }

        out.append('\n')
        out.append(INDENT.repeat(depth))
        out.append(close)
    }

    private fun appendString(
        out: StringBuilder,
        text: String,
    ) {
        out.append('"')

        for (char in text) {
            when (char) {
                '"' -> out.append("\\\"")
                '\\' -> out.append("\\\\")
                '\b' -> out.append("\\b")
                '\u000C' -> out.append("\\f")
                '\n' -> out.append("\\n")
                '\r' -> out.append("\\r")
                '\t' -> out.append("\\t")
                in '\u0000'..'\u001F' -> out.append("\\u%04x".format(char.code))
                else -> out.append(char)
            }
        }

        out.append('"')
    }
}

internal class ExportRow(
    element: JsonElement,
) {
    private val fields = element as? JsonObject ?: throw SerializationException("Expected an object")

    fun row(key: String): ExportRow = required(key) { ExportRow(it) }

    fun rows(key: String): List<ExportRow> = required(key) { list(it) }

    fun rowsOrEmpty(key: String): List<ExportRow> = optional(key) { list(it) } ?: emptyList()

    fun string(key: String): String = required(key) { text(it) }

    fun stringOrNull(key: String): String? = optional(key) { text(it) }

    fun int(key: String): Int = required(key) { integer(it) }

    fun intOrNull(key: String): Int? = optional(key) { integer(it) }

    fun boolean(key: String): Boolean = required(key) { flag(it) }

    fun booleanOrNull(key: String): Boolean? = optional(key) { flag(it) }

    fun instant(key: String): Instant = required(key) { parsed(it) { text -> InstantSerializer.parse(text) } }

    fun instantOrNull(key: String): Instant? = optional(key) { parsed(it) { text -> InstantSerializer.parse(text) } }

    fun <Owner> id(key: String): Identifier<Owner> = required(key) { parsed(it) { text -> Identifier.parse(text) } }

    fun <Owner> idOrNull(key: String): Identifier<Owner>? =
        optional(key) { parsed(it) { text -> Identifier.parse(text) } }

    fun date(key: String): LocalDate = required(key) { parsed(it) { text -> LocalDate.parse(text) } }

    fun dateOrNull(key: String): LocalDate? = optional(key) { parsed(it) { text -> LocalDate.parse(text) } }

    fun month(key: String): YearMonth = required(key) { parsed(it) { text -> YearMonth.parse(text) } }

    fun monthOrNull(key: String): YearMonth? = optional(key) { parsed(it) { text -> YearMonth.parse(text) } }

    fun <T> raw(
        key: String,
        of: (String) -> T?,
    ): T = required(key) { parsed(it, of) }

    fun <T> rawOrNull(
        key: String,
        of: (String) -> T?,
    ): T? = optional(key) { parsed(it, of) }

    fun <T> required(
        key: String,
        read: (JsonElement) -> T,
    ): T {
        val element = fields[key] ?: throw SerializationException("Missing key: $key")

        if (element is JsonNull) {
            throw SerializationException("Null for key: $key")
        }

        return read(element)
    }

    fun <T> optional(
        key: String,
        read: (JsonElement) -> T,
    ): T? {
        val element = fields[key] ?: return null

        if (element is JsonNull) {
            return null
        }

        return read(element)
    }

    private companion object {
        fun list(element: JsonElement): List<ExportRow> {
            val array = element as? JsonArray ?: throw SerializationException("Expected an array")

            return array.map { ExportRow(it) }
        }

        fun primitive(element: JsonElement): JsonPrimitive =
            element as? JsonPrimitive ?: throw SerializationException("Expected a value")

        fun text(element: JsonElement): String {
            val value = primitive(element)

            if (!value.isString) {
                throw SerializationException("Expected a string")
            }

            return value.content
        }

        fun integer(element: JsonElement): Int {
            val value = primitive(element)

            if (value.isString) {
                throw SerializationException("Expected a number")
            }

            return try {
                BigDecimal(value.content).intValueExact()
            } catch (_: ArithmeticException) {
                throw SerializationException("Expected an integer: ${value.content}")
            } catch (_: NumberFormatException) {
                throw SerializationException("Expected a number: ${value.content}")
            }
        }

        fun flag(element: JsonElement): Boolean {
            val value = primitive(element)

            if (value.isString) {
                throw SerializationException("Expected a boolean")
            }

            return when (value.content) {
                "true" -> true
                "false" -> false
                else -> throw SerializationException("Expected a boolean: ${value.content}")
            }
        }

        fun <T> parsed(
            element: JsonElement,
            of: (String) -> T?,
        ): T {
            val content = text(element)

            return of(content) ?: throw SerializationException("Invalid value: $content")
        }
    }
}
