package com.yossibank.kakeibot.core.concepts.date

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File

@Serializable
internal class ValidityFixture<T>(
    val valid: List<T>,
    val invalid: List<T>,
) {
    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        fun <T> load(
            path: String,
            serializer: KSerializer<T>,
        ): ValidityFixture<T> {
            val root = System.getProperty("fixtures") ?: error("fixtures の場所が渡されていない")
            val text = File(root, path).readText()

            return json.decodeFromString(serializer(serializer), text)
        }
    }
}
