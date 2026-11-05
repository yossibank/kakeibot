package com.yossibank.kakeibot.core.support

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File

object CoreFixture {
    private val json = Json { ignoreUnknownKeys = true }

    fun <T> cases(
        path: String,
        serializer: KSerializer<T>,
    ): List<T> {
        val root = System.getProperty("fixtures") ?: error("fixtures の場所が渡されていない")
        val text = File(root, path).readText()

        return json.decodeFromString(Cases.serializer(serializer), text).cases
    }

    @Serializable
    private class Cases<T>(
        val cases: List<T>,
    )
}
