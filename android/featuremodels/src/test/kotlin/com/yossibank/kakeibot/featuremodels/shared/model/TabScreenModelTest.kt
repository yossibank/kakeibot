package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.featuremodels.screens.tabs.assets.model.AssetsModel
import com.yossibank.kakeibot.featuremodels.screens.tabs.home.model.HomeModel
import com.yossibank.kakeibot.featuremodels.screens.tabs.records.model.RecordsModel
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.model.ReviewModel
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.modelTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TabScreenModelTest {
    @Test
    fun setsTodayOnTabModels() = modelTest(today = "2026-10-17") { setup ->
        val tabs = setup.tabs()
        val next = setup.today.adding(days = 1)

        tabs.home.setToday(next)
        tabs.records.setToday(next)
        tabs.review.setToday(next)
        tabs.assets.setToday(next)

        assertEquals(next, tabs.home.state.today)
        assertEquals(next, tabs.records.state.today)
        assertEquals(next, tabs.review.state.today)
        assertEquals(next, tabs.assets.input.today)
    }

    @Test
    fun failsLoadOnlyForListTabs() = modelTest(today = "2026-10-17") { setup ->
        val tabs = setup.tabs()
        val wasFailed = tabs.records.isLoadFailed

        tabs.home.input.overview = Loadable.Failed
        tabs.records.input.list = Loadable.Failed
        tabs.review.input.list = Loadable.Failed
        tabs.assets.input.list = Loadable.Failed

        assertFalse(wasFailed)
        assertFalse(tabs.home.isLoadFailed)
        assertTrue(tabs.records.isLoadFailed)
        assertTrue(tabs.review.isLoadFailed)
        assertTrue(tabs.assets.isLoadFailed)
    }

    private class Tabs(
        val home: HomeModel,
        val records: RecordsModel,
        val review: ReviewModel,
        val assets: AssetsModel,
    )

    private fun ModelTestSetup.tabs(): Tabs {
        val round = ObservationRound()

        return Tabs(
            home = HomeModel(parts = parts, today = today, round = round),
            records = RecordsModel(parts = parts, today = today, round = round),
            review = ReviewModel(parts = parts, today = today, round = round),
            assets = AssetsModel(parts = parts, today = today, round = round),
        )
    }
}
