package com.yossibank.kakeibot.featuremodels.screens.tabs.review.model

import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.failReads
import com.yossibank.kakeibot.featuremodels.support.failWrites
import com.yossibank.kakeibot.featuremodels.support.failingEntryList
import com.yossibank.kakeibot.featuremodels.support.failingFirst
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.reviewKind
import com.yossibank.kakeibot.store.records.settingkeys.reviewScale
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull

class ReviewModelNoticeTest {
    @Test
    fun showsNoticeWhenListFails() = modelTest(today = "2026-10-17") { setup ->
        setup.database.setSetting(key = SettingKey.reviewKind, to = ReviewKind.income)
        val model = setup.reviewModel(entryList = failingEntryList)

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.errorNotice.message.isNotEmpty() }

        assertEquals("記録を読めませんでした", model.state.errorNotice.message)
        assertEquals(ReviewKind.income, model.input.kind)
        assertNull(model.input.list.value)
        assertEquals(0L, model.output.total)
    }

    @Test
    fun marksListFailureUntilRetried() = modelTest(today = "2026-10-17") { setup ->
        val entryList = setup.database.entryListUpdates().failingFirst(times = 4)
        val model = setup.reviewModel(entryList = entryList)

        setup.scope.launch { model.observe() }
        ModelWait.until { model.input.list.isFailed }
        val message = model.state.errorNotice.message
        val list = model.input.list.value
        model.retry()
        ModelWait.until { model.input.list.isLoaded }

        assertEquals("記録を読めませんでした", message)
        assertNull(list)
        assertFalse(model.input.list.isFailed)
    }

    @Test
    fun showsNoticeWhenSelectionCannotBeRead() = modelTest(today = "2026-10-17") { setup ->
        setup.database.failReads(of = "setting")
        val model = setup.reviewModel()

        model.loadSelection()

        assertEquals("記録を読めませんでした", model.state.errorNotice.message)
        assertEquals(ReviewPeriod.Scale.month, model.input.scale)
        assertEquals(ReviewKind.expense, model.input.kind)
    }

    @Test
    fun showsNoticeWhenSelectionCannotBeSaved() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()
        setup.database.failWrites(to = "setting")

        model.setScale(ReviewPeriod.Scale.year)
        model.setKind(ReviewKind.balance)
        model.saveSelection()

        assertEquals("保存できませんでした", model.state.errorNotice.message)
        assertEquals(ReviewPeriod.Scale.year, model.input.scale)
        assertEquals(ReviewKind.balance, model.input.kind)
        assertEquals(ReviewPeriod.Scale.month, setup.database.setting(SettingKey.reviewScale))
        assertEquals(ReviewKind.expense, setup.database.setting(SettingKey.reviewKind))
    }

    @Test
    fun keepsListNoticeAfterSaving() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel(entryList = failingEntryList)
        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.errorNotice.message.isNotEmpty() }

        model.setKind(ReviewKind.income)
        model.saveSelection()

        assertEquals("記録を読めませんでした", model.state.errorNotice.message)
        assertEquals(ReviewKind.income, setup.database.setting(SettingKey.reviewKind))
    }

    @Test
    fun keepsNoticeAfterLaterSuccess() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()
        setup.database.failWrites(to = "setting")

        model.saveSelection()
        model.loadSelection()

        assertEquals("保存できませんでした", model.state.errorNotice.message)
    }

    @Test
    fun closesNoticeByHand() = modelTest(today = "2026-10-17") { setup ->
        setup.database.failReads(of = "setting")
        val model = setup.reviewModel()
        model.loadSelection()

        model.state.errorNotice.clear()

        assertEquals("", model.state.errorNotice.message)
    }

    private fun ModelTestSetup.reviewModel(
        entryList: Flow<EntryList> = database.entryListUpdates(),
    ) = ReviewModel(
        parts = parts(entryList = entryList),
        today = today,
        round = ObservationRound(),
    )
}
