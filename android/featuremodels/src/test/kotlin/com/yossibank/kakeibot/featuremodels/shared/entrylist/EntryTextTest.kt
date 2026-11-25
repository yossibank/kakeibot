package com.yossibank.kakeibot.featuremodels.shared.entrylist

import com.yossibank.kakeibot.featuremodels.support.ModelFixture
import org.junit.Test
import kotlin.test.assertEquals

class EntryTextTest {
    @Test
    fun describesDate() {
        ModelFixture.cases("entry/entry-date-text.json").forEach { case ->
            val description = EntryText.dateText(
                date = case.date("date"),
                today = case.date("today"),
            )

            assertEquals(case.text("text"), description, case.summary)
        }
    }

    @Test
    fun shortensDate() {
        ModelFixture.cases("entry/entry-date-text.json").forEach { case ->
            val description = EntryText.shortDateText(
                date = case.date("date"),
                today = case.date("today"),
            )

            assertEquals(case.text("short"), description, case.summary)
        }
    }
}
