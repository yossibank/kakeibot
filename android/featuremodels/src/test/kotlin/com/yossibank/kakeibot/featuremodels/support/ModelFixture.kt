package com.yossibank.kakeibot.featuremodels.support

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.io.File

object ModelFixture {
    class Case(
        private val fields: JsonObject,
    ) {
        val summary: String
            get() = text("summary")

        fun text(key: String): String = checkNotNull(fields[key]) {
            "$key が無い"
        }.jsonPrimitive.content

        fun date(key: String): LocalDate = checkNotNull(LocalDate.parse(text(key))) {
            "$key が日付でない"
        }

        fun number(key: String): Long = text(key).toLong()

        fun numbers(key: String): List<Long> = checkNotNull(fields[key]) { "$key が無い" }
            .jsonArray
            .map { it.jsonPrimitive.content.toLong() }

        fun texts(key: String): List<String?> = checkNotNull(fields[key]) { "$key が無い" }
            .jsonArray
            .map { if (it is JsonNull) null else it.jsonPrimitive.content }
    }

    fun cases(path: String): List<Case> {
        val root = checkNotNull(System.getProperty("fixtures")) { "fixtures の場所が渡されていない" }
        val text = File(root, path).readText(Charsets.UTF_8)

        return Json
            .parseToJsonElement(text)
            .jsonObject
            .getValue("cases")
            .jsonArray
            .map { Case(it.jsonObject) }
    }
}
