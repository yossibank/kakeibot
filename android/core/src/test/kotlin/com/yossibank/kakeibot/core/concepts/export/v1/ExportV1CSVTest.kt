package com.yossibank.kakeibot.core.concepts.export.v1

import org.junit.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertTrue

class ExportV1CSVTest {
    @Test
    fun writesFixtureRows() {
        val json = ExportFixture.data("export/export-v1.json")
        val expected = ExportFixture.data("export/export-v1.csv")
        val csv = ExportV1.of(json).data.csv()

        assertContentEquals(expected, csv)
    }

    @Test
    fun quotesFieldsWithCommasAndQuotes() {
        val lines = csvLines(memo = "本, \"上巻\"")

        assertTrue(lines[1].endsWith(",\"本, \"\"上巻\"\"\""))
    }

    @Test
    fun prefixesMemoStartingWithMinus() {
        val lines = csvLines(memo = "-1")

        assertTrue(lines[1].endsWith(",'-1"))
    }

    private fun csvLines(memo: String): List<String> {
        val json = ExportFixture.data("export/export-v1.json")
        val tables = ExportV1.of(json).data
        val entry = tables.entries[0].copy(memo = memo)

        val data = tables.copy(entries = listOf(entry)).csv()
        val csv = data.toString(Charsets.UTF_8)

        return csv.split("\r\n")
    }
}
