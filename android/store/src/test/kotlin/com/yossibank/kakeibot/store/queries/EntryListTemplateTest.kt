package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.setting.TemplateOrder
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.ordered
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class EntryListTemplateTest {
    @Test
    fun ordersByNameInJapanese() {
        val today = assertNotNull(LocalDate.parse("2026-10-17"))

        val names = listOf(
            "ｂ",
            "10 円",
            "あ",
            "A",
            "2 円",
        )

        val list = EntryList(
            days = emptyList(),
            categories = emptyMap(),
            tags = emptyMap(),
            wallets = emptyMap(),
            icons = emptyMap(),
        )

        val templates = names.mapIndexed { order, name ->
            template(
                name = name,
                sortOrder = order,
            )
        }

        val ordered = list.ordered(
            templates = templates,
            by = TemplateOrder.byName,
            today = today,
        )

        assertEquals(
            listOf(
                "2 円",
                "10 円",
                "A",
                "ｂ",
                "あ",
            ),
            ordered.map { it.name },
        )
    }
}

private fun template(
    name: String,
    sortOrder: Int,
): EntryTemplate {
    val now = Instant.ofEpochSecond(1_791_000_000)

    return EntryTemplate(
        name = name,
        type = Entry.Kind.expense,
        amount = null,
        categoryId = Identifier(),
        walletId = Identifier(),
        sortOrder = sortOrder,
        createdAt = now,
        updatedAt = now,
    )
}
