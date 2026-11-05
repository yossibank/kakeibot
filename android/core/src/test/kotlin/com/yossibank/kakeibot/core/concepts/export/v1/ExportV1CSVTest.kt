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
    fun quotesFieldsWithLineBreaks() {
        for (memo in listOf("1行目\n2行目", "1行目\r2行目", "1行目\r\n2行目")) {
            val csv = csvText(memo = memo)

            assertTrue(csv.endsWith(",\"$memo\"\r\n"), memo)
        }
    }

    @Test
    fun prefixesMemoStartingWithMinus() {
        val lines = csvLines(memo = "-1")

        assertTrue(lines[1].endsWith(",'-1"))
    }

    @Test
    fun writesAdjustmentBeyondIntRange() {
        val tables = ExportV1.of(ExportFixture.data("export/export-v1.json")).data
        val adjustment = tables.adjustments.first().copy(amount = 3_000_000_000L)

        val csv = tables.copy(adjustments = listOf(adjustment)).csv().toString(Charsets.UTF_8)

        assertTrue(csv.contains(",調整,3000000000,"))
    }

    private fun csvLines(memo: String): List<String> = csvText(memo).split("\r\n")

    private fun csvText(memo: String): String {
        val json = ExportFixture.data("export/export-v1.json")
        val tables = ExportV1.of(json).data
        val entry = tables.entries[0].copy(memo = memo)

        return tables.copy(entries = listOf(entry), adjustments = emptyList()).csv().toString(Charsets.UTF_8)
    }
}
