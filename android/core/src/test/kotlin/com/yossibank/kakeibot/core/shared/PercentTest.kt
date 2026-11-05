package com.yossibank.kakeibot.core.shared

import org.junit.Test
import kotlin.test.assertEquals

class PercentTest {
    @Test
    fun floorsToWholePercent() {
        val cases = listOf(
            Triple(290_000L, 1_000_000L, 29),
            Triple(999L, 1000L, 99),
            Triple(0L, 1000L, 0),
            Triple(1000L, 1000L, 100),
            Triple(2000L, 1000L, 100),
            Triple(-500L, 1000L, 0),
            Triple(500L, 0L, 0),
            Triple(500L, -1L, 0),
        )

        for ((part, whole, expected) in cases) {
            assertEquals(expected, Percent.floor(part, of = whole), "$part / $whole")
        }
    }

    @Test
    fun sharesAddUpToHundred() {
        val cases = listOf(
            listOf(42400L, 36400L, 21200L) to listOf(43, 36, 21),
            listOf(30000L, 50000L) to listOf(38, 62),
            listOf(1L, 1L, 1L) to listOf(34, 33, 33),
            listOf(20L, 30L, 50L) to listOf(20, 30, 50),
            listOf(100L) to listOf(100),
            listOf(0L, 0L) to listOf(0, 0),
        )

        for ((parts, expected) in cases) {
            assertEquals(expected, Percent.shares(parts), "$parts")
        }
    }

    @Test
    fun floorsBeyondIntRange() {
        val limit = 999_999_999L

        assertEquals(33, Percent.floor(3 * limit, of = 9 * limit))
        assertEquals(100, Percent.floor(3_000_000_000L, of = 3_000_000_000L))
    }

    @Test
    fun sharesBeyondIntRange() {
        val limit = 999_999_999L

        assertEquals(listOf(34, 33, 33), Percent.shares(listOf(limit, limit, limit)))
        assertEquals(listOf(50, 50), Percent.shares(listOf(3_000_000_000L, 3_000_000_000L)))
    }
}
