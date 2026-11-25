package com.yossibank.kakeibot.featuremodels.shared.period

import com.yossibank.kakeibot.featuremodels.support.ModelFixture
import org.junit.Test
import kotlin.test.assertEquals

class PeriodTextTest {
    @Test
    fun showsYearOnlyOutsideThisYear() {
        ModelFixture.cases("date/period-text-day.json").forEach { case ->
            val day = PeriodText.day(
                date = case.date("date"),
                today = case.date("today"),
            )

            assertEquals(case.text("text"), day, case.summary)
        }
    }

    @Test
    fun showsYearOfRangeOutsideThisYear() {
        ModelFixture.cases("date/period-text-range.json").forEach { case ->
            val range = PeriodText.range(
                period = case.date("lower")..case.date("upper"),
                today = case.date("today"),
            )

            assertEquals(case.text("text"), range, case.summary)
        }
    }
}
