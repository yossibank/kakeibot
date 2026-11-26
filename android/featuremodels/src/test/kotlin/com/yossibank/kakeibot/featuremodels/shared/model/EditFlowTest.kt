package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.featuremodels.shared.notice.Deletion
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EditFlowTest {
    @Test
    fun closesWithoutAskingWhenUnchanged() {
        val flow = EditFlow(task = ModelTask(), source = FakeSource())

        flow.close()
        val outcome = flow.state.outcome.value

        assertNull(flow.state.prompt.current)
        assertEquals(true, outcome?.closes)
        assertNull(outcome?.saved)
    }

    @Test
    fun asksBeforeDiscardingChanges() {
        val source = FakeSource(isChanged = true)
        val flow = EditFlow(task = ModelTask(), source = source)

        flow.close()
        val asked = flow.state.prompt.current
        val sent = flow.state.outcome.count
        flow.discard()

        assertEquals(EditFlow.Prompt.discard, asked)
        assertEquals(0, sent)
        assertNull(flow.state.prompt.current)
        assertEquals(true, flow.state.outcome.value?.closes)
    }

    @Test
    fun putsOpenPartAwayBeforeClosingOnBack() {
        val source = FakeSource(isResting = true)
        val flow = EditFlow(task = ModelTask(), source = source)

        flow.back()
        val first = flow.state.outcome.count
        flow.back()

        assertEquals(0, first)
        assertEquals(1, flow.state.outcome.count)
    }

    @Test
    fun namesProblemInsteadOfSaving() = runTest {
        val source = FakeSource(problem = "名前を入れてください")
        val flow = EditFlow(task = ModelTask(), source = source)

        val saved = flow.save()

        assertNull(saved)
        assertEquals(0, source.storeCount)
        assertFalse(flow.output.canSave)
        assertEquals("名前を入れてください", flow.output.saveTitle)
        assertEquals("名前を入れてください", flow.state.task.message)
        assertEquals(0, flow.state.outcome.count)
    }

    @Test
    fun namesSaveByWhetherEditing() {
        val adding = EditFlow(task = ModelTask(), source = FakeSource())
        val editing = EditFlow(task = ModelTask(), source = FakeSource(isEditing = true))

        assertEquals("追加する", adding.output.saveTitle)
        assertEquals("変更を保存", editing.output.saveTitle)
        assertTrue(editing.output.canSave)
    }

    @Test
    fun ignoresSecondSaveWhileSaving() = runTest {
        val task = ModelTask()
        val release = CompletableDeferred<Unit>()
        val source = FakeSource(task = task, release = release)
        val flow = EditFlow(task = task, source = source)

        val first = launch(start = CoroutineStart.UNDISPATCHED) { flow.save() }
        val second = flow.save()
        release.complete(Unit)
        first.join()

        assertNull(second)
        assertEquals(1, source.storeCount)
        assertEquals(1, flow.state.outcome.count)
        assertEquals("保存した", flow.state.outcome.value?.saved)
    }

    @Test
    fun asksBeforeHidingChanges() = runTest {
        val changed = EditFlow(
            task = ModelTask(),
            source = FakeSource(
                isEditing = true,
                isChanged = true,
            ),
        )
        val unchanged = EditFlow(task = ModelTask(), source = FakeSource(isEditing = true))

        changed.toggleHidden()
        unchanged.toggleHidden()

        assertEquals(EditFlow.Prompt.hideChanges, changed.state.prompt.current)
        assertEquals(0, changed.state.outcome.count)
        assertNull(unchanged.state.prompt.current)
        assertEquals(true, unchanged.state.outcome.value?.isHidden)
    }

    @Test
    fun asksBeforeHidingWhenSourceAsks() = runTest {
        val source = FakeSource(
            isEditing = true,
            isChanged = true,
            asksBeforeHiding = true,
        )
        val flow = EditFlow(task = ModelTask(), source = source)

        flow.toggleHidden()
        val asked = flow.state.prompt.current

        flow.continueHiding()

        assertEquals(EditFlow.Prompt.hide, asked)
        assertEquals(EditFlow.Prompt.hideChanges, flow.state.prompt.current)
        assertEquals(0, flow.state.outcome.count)
    }

    @Test
    fun keepsSheetOpenWhenNothingToDelete() = runTest {
        val flow = EditFlow(task = ModelTask(), source = FakeSource())

        val deletion = flow.delete()

        assertNull(deletion)
        assertEquals(0, flow.state.outcome.count)
    }
}

private class FakeSource(
    override val isEditing: Boolean = false,
    override val isChanged: Boolean = false,
    override val problem: String? = null,
    override val asksBeforeHiding: Boolean = false,
    private val isResting: Boolean = false,
    private val task: ModelTask = ModelTask(),
    private val release: CompletableDeferred<Unit>? = null,
) : EditFlowSource<String> {
    var storeCount = 0
        private set

    private var isOpen = isResting

    override suspend fun store(): String? {
        storeCount += 1

        return task.attempt(failure = ModelTask.saveFailed) {
            release?.await()
            "保存した"
        }
    }

    override fun rest(): Boolean {
        val wasOpen = isOpen

        isOpen = false

        return wasOpen
    }

    override suspend fun remove(): Deletion? = null
}
