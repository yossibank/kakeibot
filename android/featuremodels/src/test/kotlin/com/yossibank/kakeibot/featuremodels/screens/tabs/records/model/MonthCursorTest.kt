package com.yossibank.kakeibot.featuremodels.screens.tabs.records.model

import com.yossibank.kakeibot.core.concepts.date.YearMonth
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MonthCursorTest {
    @Test
    fun startsAtCurrentMonth() {
        assertNull(RecordsModel.MonthCursor().month)
    }

    @Test
    fun movesToMonthAndBackToCurrent() {
        val month = checkNotNull(YearMonth.parse("2026-09"))
        val moved = RecordsModel.MonthCursor().moved(to = month)

        assertEquals(month, moved.month)
        assertNull(moved.current().month)
    }
}
