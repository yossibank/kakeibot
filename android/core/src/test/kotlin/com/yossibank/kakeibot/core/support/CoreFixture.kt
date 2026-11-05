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
    ): List<T> = json.decodeFromString(Cases.serializer(serializer), read(path)).cases

    fun <T> validity(
        path: String,
        serializer: KSerializer<T>,
    ): Validity<T> = json.decodeFromString(Validity.serializer(serializer), read(path))

    fun data(path: String): ByteArray {
        val root = System.getProperty("fixtures") ?: error("fixtures の場所が渡されていない")

        return File(root, path).readBytes()
    }

    private fun read(path: String): String = data(path).toString(Charsets.UTF_8)

    @Serializable
    class Validity<T>(
        val valid: List<T>,
        val invalid: List<T>,
    )

    @Serializable
    private class Cases<T>(
        val cases: List<T>,
    )
}
