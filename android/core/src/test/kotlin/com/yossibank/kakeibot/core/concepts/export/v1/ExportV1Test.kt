package com.yossibank.kakeibot.core.concepts.export.v1

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.io.File
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ExportV1Test {
    class Single {
        @Test
        fun roundTripsFixture() {
            val fixture = ExportFixture.data("export/export-v1.json")

            val export = ExportV1.of(fixture)
            val written = export.json()
            val reread = ExportV1.of(written)

            assertEquals(ExportFixture.jsonObject(fixture), ExportFixture.jsonObject(written))
            assertEquals(export, reread)
        }

        @Test
        fun readsFileWithoutTemplates() {
            val json = ExportFixture.edited { tables ->
                tables.remove("templates")
                tables.mapRows("entries") { it.remove("templateId") }
            }

            val export = ExportV1.of(json)

            assertTrue(export.data.templates.isEmpty())
            assertFalse(export.data.entries.isEmpty())
            assertTrue(export.data.entries.all { it.templateId == null })
        }

        @Test
        fun readsFileWithoutTags() {
            val json = ExportFixture.edited { tables ->
                tables.remove("tags")

                for (key in listOf("entries", "templates")) {
                    tables.mapRows(key) { it.remove("tagId") }
                }
            }

            val export = ExportV1.of(json)

            assertTrue(export.data.tags.isEmpty())
            assertTrue(export.data.entries.all { it.tagId == null })
            assertTrue(export.data.templates.all { it.tagId == null })
        }

        @Test
        fun readsFileWithoutShelfIcons() {
            val json = ExportFixture.edited { tables ->
                tables.remove("shelfIcons")
            }

            val export = ExportV1.of(json)

            assertTrue(export.data.shelfIcons.isEmpty())
            assertFalse(export.data.icons.isEmpty())
        }

        @Test
        fun readsTemplatesAndRecurringsWithoutArchivedAt() {
            val json = ExportFixture.edited { tables ->
                for (key in listOf("templates", "recurrings")) {
                    tables.mapRows(key) { it.remove("archivedAt") }
                }
            }

            val export = ExportV1.of(json)

            assertFalse(export.data.templates.isEmpty())
            assertTrue(export.data.templates.all { it.archivedAt == null })
            assertFalse(export.data.recurrings.isEmpty())
            assertTrue(export.data.recurrings.all { it.archivedAt == null })
        }

        @Test
        fun readsRecurringsWithoutHolidayShift() {
            val json = ExportFixture.edited { tables ->
                tables.mapRows("recurrings") { it.remove("holidayShift") }
            }

            val export = ExportV1.of(json)
            val shifts = export.data.recurrings.map { it.holidayShift }

            assertFalse(shifts.isEmpty())
            assertTrue(shifts.all { it == HolidayShift.none })
        }

        @Test
        fun readsTemplatesAndRecurringsWithoutBillShift() {
            val json = ExportFixture.withBillShift(null)

            val export = ExportV1.of(json)
            val templates = export.data.templates.map { it.billShift }
            val recurrings = export.data.recurrings.map { it.billShift }

            assertFalse(templates.isEmpty())
            assertFalse(recurrings.isEmpty())
            assertTrue(templates.all { it == 0 })
            assertTrue(recurrings.all { it == 0 })
        }

        @Test
        fun readsWalletsWithoutLoanAmount() {
            val json = ExportFixture.edited { tables ->
                tables.mapRows("wallets") { it.remove("loanAmount") }
            }

            val export = ExportV1.of(json)
            val amounts = export.data.wallets.map { it.loanAmount }

            assertFalse(amounts.isEmpty())
            assertTrue(amounts.all { it == null })
        }

        @Test
        fun readsEntriesWithoutBillMonth() {
            val json = ExportFixture.withoutEntryKey("billMonth")

            val export = ExportV1.of(json)
            val months = export.data.entries.map { it.billMonth }

            assertFalse(months.isEmpty())
            assertTrue(months.all { it == null })
        }

        @Test
        fun readsEntriesWithoutTaxIncludedAsExclusive() {
            val json = ExportFixture.withoutEntryKey("taxIncluded")

            val export = ExportV1.of(json)
            val flags = export.data.entries.map { it.taxIncluded }

            assertFalse(flags.isEmpty())
            assertTrue(flags.all { !it })
        }

        @Test
        fun readsEntriesWithoutTransferId() {
            val json = ExportFixture.withoutEntryKey("transferId")

            val export = ExportV1.of(json)
            val transfers = export.data.entries.map { it.transferId }

            assertFalse(transfers.isEmpty())
            assertTrue(transfers.all { it == null })
        }

        @Test
        fun rejectsFeeWithoutTransfer() {
            val json = ExportFixture.edited { tables ->
                val rows = tables.getValue("entries").jsonArray.filter {
                    it.jsonObject["type"]?.jsonPrimitive?.content != "transfer"
                }

                tables["entries"] = JsonArray(rows)
            }

            assertFailsWith<ExportV1.ReadError.MissingTransfer> {
                ExportV1.of(json)
            }
        }

        @Test
        fun skipsSettingsWithUnknownKey() {
            val rows = ExportFixture.settingRows
            val settings = rows.valid + rows.invalid

            val json = ExportFixture.withSettings(
                settings.map { row ->
                    JsonObject(row.mapValues { JsonPrimitive(it.value) })
                },
            )

            val export = ExportV1.of(json)
            val keys = export.data.settings.map { it.key.rawValue }

            assertEquals(rows.valid.mapNotNull { it["key"] }, keys)
        }

        @Test
        fun rejectsSettingWithBrokenValue() {
            val row = JsonObject(
                mapOf(
                    "key" to JsonPrimitive("week_start"),
                    "value" to JsonPrimitive(1),
                ),
            )

            val json = ExportFixture.withSettings(listOf(row))

            assertFailsWith<SerializationException> {
                ExportV1.of(json)
            }
        }
    }

    @RunWith(Parameterized::class)
    class ClampsBillShiftOutOfRange(
        private val shift: Int,
        private val expected: Int,
    ) {
        @Test
        fun clampsBillShiftOutOfRange() {
            val json = ExportFixture.withBillShift(shift)

            val export = ExportV1.of(json)
            val templates = export.data.templates.map { it.billShift }
            val recurrings = export.data.recurrings.map { it.billShift }

            assertFalse(templates.isEmpty())
            assertFalse(recurrings.isEmpty())
            assertTrue(templates.all { it == expected })
            assertTrue(recurrings.all { it == expected })
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0} -> {1}")
            fun cases(): List<Array<Int>> = listOf(
                arrayOf(-1, 0),
                arrayOf(5, 2),
            )
        }
    }

    @RunWith(Parameterized::class)
    class SupportedHeader(
        private val header: Header,
    ) {
        @Test
        fun readsSupportedHeader() {
            val json = ExportFixture.withHeader(header)
            val export = ExportV1.of(json)

            assertEquals(ExportV1.Platform.ios, export.app.platform)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<Header> = ExportFixture.headers.valid
        }
    }

    @RunWith(Parameterized::class)
    class UnsupportedHeader(
        private val header: Header,
    ) {
        @Test
        fun rejectsUnsupportedHeader() {
            val json = ExportFixture.withHeader(header)

            assertFailsWith<ExportV1.ReadError> {
                ExportV1.of(json)
            }
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<Header> = ExportFixture.headers.invalid
        }
    }

    @Serializable
    data class Header(
        val format: String,
        val version: Int,
    ) {
        override fun toString(): String = "$format v$version"
    }
}

internal object ExportFixture {
    val headers: CoreFixture.Validity<ExportV1Test.Header>
        get() = CoreFixture.validity(
            "export/export-v1-header.json",
            ExportV1Test.Header.serializer(),
        )

    val settingRows: CoreFixture.Validity<Map<String, String>>
        get() = CoreFixture.validity(
            "export/export-v1-setting.json",
            MapSerializer(
                String.serializer(),
                String.serializer(),
            ),
        )

    fun data(path: String): ByteArray {
        val root = System.getProperty("fixtures") ?: error("fixtures の場所が渡されていない")

        return File(root, path).readBytes()
    }

    fun jsonObject(data: ByteArray): JsonObject = Json.parseToJsonElement(data.toString(Charsets.UTF_8)).jsonObject

    fun edited(edit: (MutableMap<String, JsonElement>) -> Unit): ByteArray {
        val root = jsonObject(data("export/export-v1.json")).toMutableMap()
        val tables = root.getValue("data").jsonObject.toMutableMap()

        edit(tables)
        root["data"] = JsonObject(tables)

        return JsonObject(root).toString().toByteArray(Charsets.UTF_8)
    }

    fun withHeader(header: ExportV1Test.Header): ByteArray {
        val root = jsonObject(data("export/export-v1.json")).toMutableMap()

        root["format"] = JsonPrimitive(header.format)
        root["version"] = JsonPrimitive(header.version)

        return JsonObject(root).toString().toByteArray(Charsets.UTF_8)
    }

    fun withSettings(settings: List<JsonElement>): ByteArray = edited { tables ->
        tables["settings"] = JsonArray(settings)
    }

    fun withBillShift(billShift: Int?): ByteArray = edited { tables ->
        for (key in listOf("templates", "recurrings")) {
            tables.mapRows(key) { row ->
                if (billShift == null) {
                    row.remove("billShift")
                } else {
                    row["billShift"] = JsonPrimitive(billShift)
                }
            }
        }
    }

    fun withoutEntryKey(key: String): ByteArray = edited { tables ->
        tables.mapRows("entries") { it.remove(key) }
    }
}

internal fun MutableMap<String, JsonElement>.mapRows(
    key: String,
    edit: (MutableMap<String, JsonElement>) -> Unit,
) {
    val rows = getValue(key).jsonArray.map { element ->
        val row = element.jsonObject.toMutableMap()

        edit(row)

        JsonObject(row)
    }

    this[key] = JsonArray(rows)
}
