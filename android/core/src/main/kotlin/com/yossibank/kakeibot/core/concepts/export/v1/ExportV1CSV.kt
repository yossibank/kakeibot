package com.yossibank.kakeibot.core.concepts.export.v1

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import java.text.BreakIterator
import java.time.Instant

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

private const val adjustmentTitle = "調整"

private data class CSVRow(
    val date: LocalDate,
    val createdAt: Instant,
    val id: String,
    val fields: List<String>,
)

fun ExportV1.Tables.csv(): ByteArray {
    val rows = listOf(csvHeader) + sortedRows.map { it.fields }

    val text = rows.joinToString(separator = "") { fields ->
        fields.joinToString(separator = ",") { escape(it) } + "\r\n"
    }

    return byteOrderMark + text.toByteArray(Charsets.UTF_8)
}

private val ExportV1.Tables.sortedRows: List<CSVRow>
    get() = (entries.map { row(it) } + adjustments.map { row(it) }).sortedWith(
        compareBy<CSVRow> { it.date }
            .thenBy { it.createdAt }
            .thenBy { it.id },
    )

private fun ExportV1.Tables.walletName(id: Identifier<Wallet>?): String =
    wallets.firstOrNull { it.id == id }?.name ?: ""

private fun ExportV1.Tables.row(entry: Entry): CSVRow {
    val categoryName = categories.firstOrNull { it.id == entry.categoryId }?.name ?: ""
    val tagName = tags.firstOrNull { it.id == entry.tagId }?.name ?: ""

    val fields = listOf(
        entry.date.toString(),
        kindTitle(entry.type),
        entry.amount.toString(),
        text(categoryName),
        text(tagName),
        text(walletName(entry.walletId)),
        text(walletName(entry.toWalletId)),
        text(entry.memo ?: ""),
    )

    return CSVRow(
        date = entry.date,
        createdAt = entry.createdAt,
        id = entry.id.toString(),
        fields = fields,
    )
}

private fun ExportV1.Tables.row(adjustment: Adjustment): CSVRow {
    val fields = listOf(
        adjustment.date.toString(),
        adjustmentTitle,
        adjustment.amount.toString(),
        "",
        "",
        text(walletName(adjustment.walletId)),
        "",
        "",
    )

    return CSVRow(
        date = adjustment.date,
        createdAt = adjustment.createdAt,
        id = adjustment.id.toString(),
        fields = fields,
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
