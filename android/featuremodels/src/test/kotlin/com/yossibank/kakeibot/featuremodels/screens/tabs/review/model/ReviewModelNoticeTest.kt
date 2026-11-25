package com.yossibank.kakeibot.featuremodels.screens.tabs.review.model

import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.allowWrites
import com.yossibank.kakeibot.featuremodels.support.failReads
import com.yossibank.kakeibot.featuremodels.support.failWrites
import com.yossibank.kakeibot.featuremodels.support.failingEntryList
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
import kotlin.test.assertNull

class ReviewModelNoticeTest {
    @Test
    fun showsNoticeWhenListFails() = modelTest(today = "2026-10-17") { setup ->
        setup.database.setSetting(key = SettingKey.reviewKind, to = ReviewKind.income)
        val model = setup.reviewModel(entryList = failingEntryList)

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.task.message.isNotEmpty() }

        assertEquals("記録を読めませんでした", model.state.task.message)
        assertEquals(ReviewKind.income, model.input.kind)
        assertNull(model.input.list)
        assertEquals(0L, model.output.total)
    }

    @Test
    fun showsNoticeWhenSelectionCannotBeRead() = modelTest(today = "2026-10-17") { setup ->
        setup.database.failReads(of = "setting")
        val model = setup.reviewModel()

        model.loadSelection()

        assertEquals("記録を読めませんでした", model.state.task.message)
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

        assertEquals("保存できませんでした", model.state.task.message)
        assertEquals(ReviewPeriod.Scale.year, model.input.scale)
        assertEquals(ReviewKind.balance, model.input.kind)
        assertEquals(ReviewPeriod.Scale.month, setup.database.setting(SettingKey.reviewScale))
        assertEquals(ReviewKind.expense, setup.database.setting(SettingKey.reviewKind))
    }

    @Test
    fun clearsNoticeAfterSavingAgain() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()
        setup.database.failWrites(to = "setting")
        model.setKind(ReviewKind.income)
        model.saveSelection()
        val failed = model.state.task.message

        setup.database.allowWrites(to = "setting")
        model.saveSelection()

        assertEquals("保存できませんでした", failed)
        assertEquals("", model.state.task.message)
        assertEquals(ReviewKind.income, setup.database.setting(SettingKey.reviewKind))
    }

    @Test
    fun closesNoticeByHand() = modelTest(today = "2026-10-17") { setup ->
        setup.database.failReads(of = "setting")
        val model = setup.reviewModel()
        model.loadSelection()

        model.state.task.clear()

        assertEquals("", model.state.task.message)
    }

    private fun ModelTestSetup.reviewModel(
        entryList: Flow<EntryList> = database.entryListUpdates(),
    ) = ReviewModel(
        database = database,
        entryList = entryList,
        today = today,
    )
}
