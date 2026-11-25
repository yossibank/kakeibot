package com.yossibank.kakeibot.featuremodels.shared.notice

import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.deleteWallet
import com.yossibank.kakeibot.store.writes.types.Deletion
import org.junit.Test
import kotlin.test.assertEquals

class DeletionNoticeTest {
    @Test
    fun namesSingleDeletedItem() = modelTest(today = "2026-11-01") { setup ->
        val wallet = setup.options().wallets.last()
        val named = setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")

        val deletion = setup.database.deleteWallet(id = wallet.id, at = setup.now)
        val recurring = setup.database.deleteRecurring(id = named.id, at = setup.now)

        assertEquals("${wallet.name} を削除しました", DeletionNotice.message(deletion))
        assertEquals("家賃 を削除しました", DeletionNotice.message(recurring))
    }

    @Test
    fun fallsBackToKindAndCount() = modelTest(today = "2026-11-01") { setup ->
        val wallets = setup.options().wallets
        val recurring = setup.saveRecurring(amount = 80000, day = 27)
        val unnamed = setup.database.deleteRecurring(id = recurring.id, at = setup.now)
        val added = setup.addWallet(kind = Wallet.Kind.cash, name = "小銭入れ")

        val merged = Deletion.merging(
            listOf(
                setup.database.deleteWallet(id = added.id, at = setup.now),
                setup.database.deleteWallet(id = wallets[1].id, at = setup.now),
            ),
        )

        assertEquals("固定費を削除しました", DeletionNotice.message(unnamed))
        assertEquals("口座 2 件を削除しました", DeletionNotice.message(merged))
        assertEquals("削除しました", DeletionNotice.message(Deletion.merging(emptyList())))
    }
}
