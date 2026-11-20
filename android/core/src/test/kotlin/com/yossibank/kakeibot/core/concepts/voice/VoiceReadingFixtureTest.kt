package com.yossibank.kakeibot.core.concepts.voice

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import kotlin.test.assertEquals

@RunWith(Parameterized::class)
class VoiceReadingFixtureTest(
    private val spoken: SpokenCase,
) {
    @Test
    fun readsSpokenText() {
        val today = LocalDate.parse(fixture.today) ?: error("today が読めない")
        val categories = fixture.categories.map(::category)
        val wallets = fixture.wallets.map(::wallet)

        val reading = VoiceReading.of(
            text = spoken.text,
            today = today,
            categories = categories,
            wallets = wallets,
        )

        val category = categories.firstOrNull { it.id == reading.categoryId }?.name
        val wallet = wallets.firstOrNull { it.id == reading.walletId }?.name

        assertEquals(spoken.amount, reading.amount)
        assertEquals(spoken.date?.let(LocalDate::parse), reading.date)
        assertEquals(spoken.category, category)
        assertEquals(spoken.wallet, wallet)
        assertEquals(spoken.memo, reading.memo)
    }

    @Serializable
    data class Fixture(
        val today: String,
        val categories: List<String>,
        val wallets: List<String>,
        val cases: List<SpokenCase>,
    )

    @Serializable
    data class SpokenCase(
        val summary: String,
        val text: String,
        val amount: Int?,
        val date: String?,
        val category: String?,
        val wallet: String?,
        val memo: String?,
    ) {
        override fun toString(): String = summary
    }

    companion object {
        private val now = Instant.ofEpochSecond(1_790_000_000)

        private val fixture: Fixture by lazy {
            val text = CoreFixture.data("voice/voice-reading.json").toString(Charsets.UTF_8)
            Json { ignoreUnknownKeys = true }.decodeFromString(Fixture.serializer(), text)
        }

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<SpokenCase> = fixture.cases

        private fun category(name: String): EntryCategory = EntryCategory(
            kind = EntryCategory.Kind.expense,
            name = name,
            iconId = Identifier(),
            sortOrder = 0,
            createdAt = now,
            updatedAt = now,
        )

        private fun wallet(name: String): Wallet = Wallet(
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
