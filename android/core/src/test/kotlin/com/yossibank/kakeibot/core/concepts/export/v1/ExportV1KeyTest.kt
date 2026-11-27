package com.yossibank.kakeibot.core.concepts.export.v1

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import org.junit.Test
import kotlin.test.assertEquals

class ExportV1KeyTest {
    @Test
    fun keepsKeysOfFixtureThroughRoundTrip() {
        val fixture = ExportFixture.data("export/export-v1.json")
        val expected = keyPaths(fixture)

        val written = keyPaths(ExportV1.of(fixture).json())

        assertEquals(emptyList(), (written - expected).sorted(), HINT)
        assertEquals(emptyList(), (expected - written).sorted(), HINT)
    }

    private companion object {
        const val HINT = "書き出しのキーを変えたら、見本と export-format.md も直す"

        fun keyPaths(data: ByteArray): Set<String> {
            val root = Json.parseToJsonElement(data.toString(Charsets.UTF_8))
            val paths = mutableSetOf<String>()

            collect(root, "", paths)

            return paths
        }

        fun collect(
            element: JsonElement,
            path: String,
            paths: MutableSet<String>,
        ) {
            when (element) {
                is JsonObject -> {
                    for ((key, child) in element) {
                        val childPath = if (path.isEmpty()) key else "$path.$key"

                        paths.add(childPath)
                        collect(child, childPath, paths)
                    }
                }

                is JsonArray -> {
                    for (child in element) {
                        collect(child, "$path[]", paths)
                    }
                }

                else -> {
                    Unit
                }
            }
        }
    }
}
