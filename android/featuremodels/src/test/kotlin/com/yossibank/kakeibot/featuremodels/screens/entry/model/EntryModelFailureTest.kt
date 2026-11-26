package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.support.failReads
import com.yossibank.kakeibot.featuremodels.support.failWrites
import com.yossibank.kakeibot.featuremodels.support.fillStorage
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entry
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EntryModelFailureTest {
    @Test
    fun tellsWhenLoadingFails() = modelTest(today = "2026-10-12") { setup ->
        setup.database.failReads(of = "entry")

        val model = setup.loadedModel()

        assertEquals("保存できませんでした", model.state.task.message)
    }

    @Test
    fun ignoresCancelledLoad() = modelTest(today = "2026-10-12") { setup ->
        val model = EntryModel(
            parts = setup.parts,
            today = setup.today,
        )

        val load = launch(start = CoroutineStart.UNDISPATCHED) { model.load() }
        val isRunning = model.state.task.isRunning
        load.cancelAndJoin()

        assertTrue(isRunning)
        assertTrue(load.isCancelled)
        assertEquals("", model.state.task.message)
        assertEquals(0, model.state.task.count)
        assertFalse(model.state.task.isRunning)
    }

    @Test
    fun tellsWhenDeletingFails() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val model = setup.loadedModel(editing = entry.id)
        setup.database.failWrites(to = "entry")

        val deleted = model.delete()

        assertFalse(deleted)
        assertEquals(entry, setup.database.entry(entry.id))
        assertEquals("保存できませんでした", model.state.task.message)
    }

    @Test
    fun deletesNothingWhenEntryIsMissing() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel(editing = Identifier())
        setup.database.failWrites(to = "entry")

        val deleted = model.delete()

        assertFalse(deleted)
        assertEquals("記録が見つかりませんでした", model.state.task.message)
    }

    @Test
    fun keepsNoticeWhenInputChanges() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.save()

        model.press(1)

        assertEquals("金額を入れてください", model.state.task.message)
    }

    @Test
    fun tellsWhenStorageIsFull() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)
        model.state.update { copy(memo = "あ".repeat(100_000)) }
        setup.database.fillStorage()

        val saved = model.save()

        assertFalse(saved)
        assertEquals("端末の空き容量が足りません", model.state.task.message)
        assertEquals(ModelTask.storageFull, model.state.task.message)
    }
}
