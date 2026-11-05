package com.yossibank.kakeibot.core.shared

import org.junit.Test
import kotlin.test.assertEquals

class PercentTest {
    @Test
    fun floorsToWholePercent() {
        val cases = listOf(
            Triple(290_000, 1_000_000, 29),
            Triple(999, 1000, 99),
            Triple(0, 1000, 0),
            Triple(1000, 1000, 100),
            Triple(2000, 1000, 100),
            Triple(-500, 1000, 0),
            Triple(500, 0, 0),
            Triple(500, -1, 0),
        )

        for ((part, whole, expected) in cases) {
            assertEquals(expected, Percent.floor(part, of = whole), "$part / $whole")
        }
    }

    @Test
    fun sharesAddUpToHundred() {
        val cases = listOf(
            listOf(42400, 36400, 21200) to listOf(43, 36, 21),
            listOf(30000, 50000) to listOf(38, 62),
            listOf(1, 1, 1) to listOf(34, 33, 33),
            listOf(20, 30, 50) to listOf(20, 30, 50),
            listOf(100) to listOf(100),
            listOf(0, 0) to listOf(0, 0),
        )

        for ((parts, expected) in cases) {
            assertEquals(expected, Percent.shares(parts), "$parts")
        }
    }
}
