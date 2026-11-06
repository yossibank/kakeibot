package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.balance
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.writes.methods.deleteValuation
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.saveValuation
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ValuationWriteTest {
    @Test
    fun replacesValuationOnTheSameDay() = runTest {
        val database = AppDatabase.inMemory()
        database.insertDefaultsIfEmpty(Instant.now())
        val options = database.entryOptions()
        val wallet = options.wallets[0]
        val day = assertNotNull(LocalDate.parse("2026-10-21"))
        val now = Instant.now()
        val investment = wallet.copy(kind = Wallet.Kind.investment)

        database.saveValuation(
            150_000,
            of = wallet.id,
            on = day,
            at = now,
        )

        database.saveValuation(
            160_000,
            of = wallet.id,
            on = day,
            at = now,
        )

        val list = database.entryList()

        val balance = investment.balance(
            with = emptyList(),
            valuations = list.valuations,
        )

        assertEquals(listOf(160_000), list.valuations.map { it.amount })
        assertEquals(160_000L, balance)

        database.close()
    }

    @Test
    fun restoresDeletedValuation() = runTest {
        val database = AppDatabase.inMemory()
        database.insertDefaultsIfEmpty(Instant.now())
        val options = database.entryOptions()
        val wallet = options.wallets[0]
        val day = assertNotNull(LocalDate.parse("2026-10-21"))

        database.saveValuation(
            150_000,
            of = wallet.id,
            on = day,
            at = Instant.now(),
        )

        val saved = database.entryList().valuations
        val id = saved[0].id

        val deletion = assertNotNull(database.deleteValuation(id))
        val deleted = database.entryList().valuations
        database.restore(deletion)
        val restored = database.entryList().valuations

        assertTrue(deleted.isEmpty())
        assertEquals(saved, restored)

        database.close()
    }

    @Test
    fun returnsNoDeletionForMissingValuation() = runTest {
        val database = AppDatabase.inMemory()
        database.insertDefaultsIfEmpty(Instant.now())
        val options = database.entryOptions()
        val wallet = options.wallets[0]
        val day = assertNotNull(LocalDate.parse("2026-10-21"))

        database.saveValuation(
            150_000,
            of = wallet.id,
            on = day,
            at = Instant.now(),
        )

        val id = database.entryList().valuations[0].id
        database.deleteValuation(id)

        val deletion = database.deleteValuation(id)

        assertNull(deletion)

        database.close()
    }
}
