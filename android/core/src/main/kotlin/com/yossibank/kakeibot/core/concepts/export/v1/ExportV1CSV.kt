package com.yossibank.kakeibot.core.concepts.export.v1

import com.yossibank.kakeibot.core.concepts.entry.Entry
import java.text.BreakIterator

private val csvHeader = listOf(
    "日付",
    "種類",
    "金額",
    "カテゴリ",
    "タグ",
    "財布",
    "振替先",
    "メモ",
)

private val byteOrderMark = byteArrayOf(
    0xEF.toByte(),
    0xBB.toByte(),
    0xBF.toByte(),
)

private val formulaPrefixes = setOf("=", "+", "-", "@")

fun ExportV1.Tables.csv(): ByteArray {
    val rows = listOf(csvHeader) + sortedEntries.map { row(it) }

    val text = rows.joinToString(separator = "") { fields ->
        fields.joinToString(separator = ",") { escape(it) } + "\r\n"
    }

    return byteOrderMark + text.toByteArray(Charsets.UTF_8)
}

private val ExportV1.Tables.sortedEntries: List<Entry>
    get() = entries.sortedWith(
        compareBy<Entry> { it.date }
            .thenBy { it.createdAt }
            .thenBy { it.id.toString() },
    )

private fun ExportV1.Tables.row(entry: Entry): List<String> {
    val categoryName = categories.firstOrNull { it.id == entry.categoryId }?.name ?: ""
    val tagName = tags.firstOrNull { it.id == entry.tagId }?.name ?: ""
    val walletName = wallets.firstOrNull { it.id == entry.walletId }?.name ?: ""
    val toWalletName = wallets.firstOrNull { it.id == entry.toWalletId }?.name ?: ""

    return listOf(
        entry.date.toString(),
        kindTitle(entry.type),
        entry.amount.toString(),
        text(categoryName),
        text(tagName),
        text(walletName),
        text(toWalletName),
        text(entry.memo ?: ""),
    )
}

private fun text(field: String): String {
    val first = firstCharacter(field) ?: return field

    if (first !in formulaPrefixes) {
        return field
    }

    return "'$field"
}

private fun firstCharacter(field: String): String? {
    val iterator = BreakIterator.getCharacterInstance()

    iterator.setText(field)

    val end = iterator.next()

    if (end == BreakIterator.DONE) {
        return null
    }

    return field.substring(0, end)
}

private fun escape(field: String): String {
    val needsQuotes = field.any { it in "\",\r\n" }

    if (!needsQuotes) {
        return field
    }

    val doubled = field.replace("\"", "\"\"")

    return "\"$doubled\""
}

private fun kindTitle(kind: Entry.Kind): String = when (kind) {
    Entry.Kind.expense -> "支出"
    Entry.Kind.income -> "収入"
    Entry.Kind.transfer -> "振替"
}
