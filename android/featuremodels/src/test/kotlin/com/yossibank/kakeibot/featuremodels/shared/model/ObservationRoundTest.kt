package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.featuremodels.screens.tabs.assets.model.AssetsModel
import com.yossibank.kakeibot.featuremodels.screens.tabs.records.model.RecordsModel
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.failingFirst
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ObservationRoundTest {
    @Test
    fun observesAgainWhenRestarted() = modelTest(today = "2026-10-17") { setup ->
        val round = ObservationRound()
        var started = 0
        var stopped = 0

        setup.scope.launch {
            round.each {
                started += 1

                try {
                    awaitCancellation()
                } finally {
                    stopped += 1
                }
            }
        }

        ModelWait.until { started == 1 }
        round.restart()
        ModelWait.until { started == 2 }

        assertEquals(1, round.count)
        assertEquals(1, stopped)
    }

    @Test
    fun restartsEveryModelSharingRound() = modelTest(today = "2026-10-17") { setup ->
        val round = ObservationRound()
        val entryList = setup.database.entryListUpdates()

        val records = RecordsModel(
            parts = setup.parts(entryList = entryList.failingFirst(times = 4)),
            today = setup.today,
            round = round,
        )

        val assets = AssetsModel(
            parts = setup.parts(entryList = entryList.failingFirst(times = 4)),
            today = setup.today,
            round = round,
        )

        setup.scope.launch { records.observe() }
        setup.scope.launch { assets.observe() }
        ModelWait.until { records.input.list.isFailed && assets.input.list.isFailed }
        val wereLoaded = records.input.list.isLoaded || assets.input.list.isLoaded
        assets.retry()
        ModelWait.until { records.input.list.isLoaded && assets.input.list.isLoaded }

        assertFalse(wereLoaded)
        assertFalse(records.input.list.isFailed)
        assertFalse(assets.input.list.isFailed)
        assertTrue(assets.output.rows.isNotEmpty())
    }
}
