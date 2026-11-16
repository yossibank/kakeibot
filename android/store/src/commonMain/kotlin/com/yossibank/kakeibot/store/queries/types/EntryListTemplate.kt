package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.setting.TemplateOrder
import com.yossibank.kakeibot.core.shared.Identifier
import java.text.Collator
import java.text.Normalizer
import java.util.Locale

fun EntryList.icon(of: EntryTemplate): Icon? {
    val category = categories[of.categoryId]

    return category?.let { icons[it.iconId] }
}

fun EntryList.detailParts(of: EntryTemplate): List<String?> {
    val category = categories[of.categoryId]?.name
    val shown = of.tagId?.let { tags[it] }?.takeIf { it.archivedAt == null }
    val tag = shown?.name
    val wallet = wallets[of.walletId]?.name

    return listOf(
        category,
        tag,
        wallet,
    )
}

fun EntryList.ordered(
    templates: List<EntryTemplate>,
    by: TemplateOrder,
    today: LocalDate,
): List<EntryTemplate> {
    val uses = if (by == TemplateOrder.frequent) templateUses(through = today) else emptyMap()

    return templates.sortedWith { lhs, rhs ->
        compare(
            lhs = lhs,
            rhs = rhs,
            by = by,
            uses = uses,
        )
    }
}

private val japanese: Locale = Locale.JAPANESE

private fun EntryList.templateUses(through: LocalDate): Map<Identifier<EntryTemplate>, Int> {
    val start = through.adding(days = 1 - TemplateOrder.frequentDays)
    val uses = mutableMapOf<Identifier<EntryTemplate>, Int>()

    for (day in days) {
        if (day.date < start || day.date > through) {
            continue
        }

        for (id in day.entries.mapNotNull { it.templateId }) {
            uses[id] = (uses[id] ?: 0) + 1
        }
    }

    return uses
}

private fun EntryList.categoryOrder(of: EntryTemplate): Int = categories[of.categoryId]?.sortOrder ?: Int.MAX_VALUE

private fun EntryList.compare(
    lhs: EntryTemplate,
    rhs: EntryTemplate,
    by: TemplateOrder,
    uses: Map<Identifier<EntryTemplate>, Int>,
): Int {
    val result = when (by) {
        TemplateOrder.manual -> 0

        TemplateOrder.frequent -> (uses[rhs.id] ?: 0).compareTo(uses[lhs.id] ?: 0)

        TemplateOrder.category -> categoryOrder(lhs).compareTo(categoryOrder(rhs))

        TemplateOrder.amount -> (rhs.amount ?: -1).compareTo(lhs.amount ?: -1)

        TemplateOrder.byName -> compareNames(
            lhs = lhs.name,
            rhs = rhs.name,
        )
    }

    return if (result != 0) result else lhs.sortOrder.compareTo(rhs.sortOrder)
}

private fun compareNames(
    lhs: String,
    rhs: String,
): Int {
    val collator = Collator.getInstance(japanese)
    val left = chunks(lhs)
    val right = chunks(rhs)

    for ((leftChunk, rightChunk) in left.zip(right)) {
        val result = if (leftChunk.isDigits && rightChunk.isDigits) {
            compareDigits(
                lhs = leftChunk.text,
                rhs = rightChunk.text,
            )
        } else {
            collator.compare(leftChunk.text, rightChunk.text)
        }

        if (result != 0) {
            return result
        }
    }

    return left.size.compareTo(right.size)
}

private data class Chunk(
    val text: String,
    val isDigits: Boolean,
)

private fun chunks(name: String): List<Chunk> {
    val folded = Normalizer.normalize(name, Normalizer.Form.NFKC).lowercase(japanese)
    val chunks = mutableListOf<Chunk>()

    for (character in folded) {
        val isDigit = character in '0'..'9'
        val last = chunks.lastOrNull()

        if (last != null && last.isDigits == isDigit) {
            chunks[chunks.lastIndex] = last.copy(text = last.text + character)
        } else {
            chunks.add(
                Chunk(
                    text = character.toString(),
                    isDigits = isDigit,
                ),
            )
        }
    }

    return chunks
}

private fun compareDigits(
    lhs: String,
    rhs: String,
): Int {
    val left = lhs.trimStart('0')
    val right = rhs.trimStart('0')

    if (left.length != right.length) {
        return left.length.compareTo(right.length)
    }

    return left.compareTo(right)
}
