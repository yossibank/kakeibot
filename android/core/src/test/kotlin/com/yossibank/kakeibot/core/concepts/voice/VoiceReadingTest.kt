package com.yossibank.kakeibot.core.concepts.voice

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class VoiceReadingTest {
    @Test
    fun readsEveryField() {
        val reading = read("昨日、駅前でランチ980円、カードで")

        assertEquals(980, reading.amount)
        assertEquals(LocalDate.of(year = 2026, month = 11, day = 11), reading.date)
        assertEquals(card.id, reading.walletId)
        assertNull(reading.categoryId)
        assertEquals("駅前でランチ", reading.memo)
        assertEquals(4, reading.count)
    }

    @Test
    fun readsAmounts() {
        val cases = listOf(
            "コンビニで1,280円" to 1280,
            "三千円" to 3000,
            "1万2000円" to 12000,
            "二万円" to 20000,
            "千五百円" to 1500,
            "ランチ 980" to 980,
            "980円を3日に" to 980,
        )

        for ((text, amount) in cases) {
            assertEquals(amount, read(text).amount, text)
        }
    }

    @Test
    fun readsDates() {
        val cases = listOf(
            "今日のランチ" to "2026-11-12",
            "おととい" to "2026-11-10",
            "一昨日" to "2026-11-10",
            "11月3日に" to "2026-11-03",
            "12月24日" to "2025-12-24",
            "3日に" to "2026-11-03",
            "15日に" to "2026-10-15",
        )

        for ((text, date) in cases) {
            assertEquals(LocalDate.parse(date), read(text).date, text)
        }
    }

    @Test
    fun keepsDateNumbersOutOfTheAmount() {
        val reading = read("3日 500円")

        assertEquals(LocalDate.of(year = 2026, month = 11, day = 3), reading.date)
        assertEquals(500, reading.amount)
    }

    @Test
    fun leavesAmountEmptyWhenOnlyADateIsSaid() {
        val reading = read("3日にコンビニ")

        assertNull(reading.amount)
        assertEquals("コンビニ", reading.memo)
    }

    @Test
    fun matchesNamesAcrossKana() {
        val reading = read("かーどで交通費 220円")

        assertEquals(card.id, reading.walletId)
        assertEquals(transport.id, reading.categoryId)
        assertEquals("交通費", reading.memo)
    }

    @Test
    fun prefersTheLongestName() {
        val reading = read("楽天カードで300円")

        assertEquals(rakuten.id, reading.walletId)
    }

    @Test
    fun usesTheModelChoiceOverNames() {
        val choice = VoiceReading.Choice(categoryIndex = 0, walletIndex = 2)
        val reading = read("交通費 カード 220円", choice = choice)

        assertEquals(food.id, reading.categoryId)
        assertEquals(rakuten.id, reading.walletId)
    }

    @Test
    fun fallsBackToNamesWhenTheChoiceIsOutOfRange() {
        val choice = VoiceReading.Choice(categoryIndex = 9, walletIndex = null)
        val reading = read("交通 220円", choice = choice)

        assertEquals(transport.id, reading.categoryId)
    }

    @Test
    fun readsNothingFromFillers() {
        val reading = read("えっと、あの")

        assertTrue(reading.isEmpty)
    }

    @Test
    fun dropsSpokenEndingsFromTheMemo() {
        val reading = read("本屋で1200円払った")

        assertEquals("本屋", reading.memo)
    }

    private fun read(
        text: String,
        choice: VoiceReading.Choice? = null,
    ): VoiceReading = VoiceReading.of(
        text = text,
        today = today,
        categories = listOf(food, transport),
        wallets = listOf(cash, card, rakuten),
        choice = choice,
    )

    private companion object {
        val now: Instant = Instant.ofEpochSecond(1_790_000_000)
        val today: LocalDate = LocalDate.of(year = 2026, month = 11, day = 12)!!

        val food = category("食費")
        val transport = category("交通")
        val cash = wallet("財布")
        val card = wallet("カード")
        val rakuten = wallet("楽天カード")

        fun category(name: String): EntryCategory = EntryCategory(
            kind = EntryCategory.Kind.expense,
            name = name,
            iconId = Identifier(),
            sortOrder = 0,
            createdAt = now,
            updatedAt = now,
        )

        fun wallet(name: String): Wallet = Wallet(
            name = name,
            kind = Wallet.Kind.cash,
            iconId = Identifier(),
            initialBalance = 0,
            sortOrder = 0,
            createdAt = now,
            updatedAt = now,
        )
    }
}
