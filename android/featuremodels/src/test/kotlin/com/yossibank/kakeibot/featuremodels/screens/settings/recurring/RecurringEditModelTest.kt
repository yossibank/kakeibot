package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.notification.NotificationAuthorization
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.notification.NotificationPermission
import com.yossibank.kakeibot.featuremodels.support.FakePermission
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.recurrings
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecurringEditModelTest {
    @Test
    fun warnsThatRemindersCannotArriveWhenDenied() = modelTest(today = "2026-10-17") { setup ->
        val client = FakePermission(authorization = NotificationAuthorization.denied)
        val model = setup.editModel(permission = client.permission)
        model.load()

        model.refreshAuthorization()
        val withoutReminder = model.output.isNotificationDenied
        model.state.update { copy(remindDaysBefore = 1) }

        assertFalse(withoutReminder)
        assertTrue(model.output.isNotificationDenied)
    }

    @Test
    fun doesNotWarnBeforeAskingForReminders() = modelTest(today = "2026-10-17") { setup ->
        val client = FakePermission(authorization = NotificationAuthorization.notDetermined)
        val model = setup.editModel(permission = client.permission)
        model.load()
        model.state.update { copy(remindDaysBefore = 1) }

        model.refreshAuthorization()

        assertFalse(model.output.isNotificationDenied)
    }

    @Test
    fun doesNotWarnWhenRemindersAreAllowed() = modelTest(today = "2026-10-17") { setup ->
        val client = FakePermission(authorization = NotificationAuthorization.allowed)
        val model = setup.editModel(permission = client.permission)
        model.load()
        model.state.update { copy(remindDaysBefore = 1) }

        model.refreshAuthorization()

        assertFalse(model.output.isNotificationDenied)
    }

    @Test
    fun asksPermissionOnlyWhenSavingWithReminder() = modelTest(today = "2026-10-17") { setup ->
        val client = FakePermission(authorization = NotificationAuthorization.notDetermined)
        val without = setup.editModel(permission = client.permission)
        without.load()
        without.press(5)
        without.state.update { copy(memo = "家賃") }

        without.flow.save()
        val askedWithout = client.requested

        val model = setup.editModel(permission = client.permission)
        model.load()
        model.press(5)
        model.state.update { copy(memo = "保険", remindDaysBefore = 1) }

        val saved = model.flow.save()

        assertNotNull(saved)
        assertFalse(askedWithout)
        assertTrue(client.requested)
    }

    @Test
    fun opensScheduleOnlyWhenAdding() = modelTest(today = "2026-10-17") { setup ->
        val adding = setup.editModel()
        val editing = setup.editModel(editingId = Identifier())

        assertTrue(adding.state.isScheduleOpen)
        assertFalse(editing.state.isScheduleOpen)
        assertFalse(adding.flow.output.isEditing)
        assertTrue(editing.flow.output.isEditing)
    }

    @Test
    fun startsNewRecurringWithGivenTransferType() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel(type = Entry.Kind.transfer)

        model.load()

        assertEquals(Entry.Kind.transfer, model.state.form.type)
        assertNull(model.state.form.categoryId)
        assertNotNull(model.state.form.toWalletId)
        assertNotEquals(model.state.form.walletId, model.state.form.toWalletId)
        assertFalse(model.flow.output.isChanged)
    }

    @Test
    fun doesNotCountClosingScheduleAsChange() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        model.load()

        model.state.toggleSchedule()

        assertFalse(model.flow.output.isChanged)
    }

    @Test
    fun savesRecurringAndGeneratesEntries() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        model.load()

        model.press(7, 8, 0, 0, 0)
        model.state.update { copy(memo = "家賃", day = 27, startDate = date("2026-09-01")) }
        val title = model.flow.output.saveTitle
        val saved = model.flow.save()
        val entries = setup.database.entryList().entries

        assertNotNull(saved)
        assertEquals("追加する", title)
        assertEquals(1, setup.database.recurrings().size)
        assertEquals(listOf("2026-09-27"), entries.map { it.date.toString() })
        assertEquals(78000, entries.first().amount)
    }

    @Test
    fun suggestsHolidayShiftFromCategory() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        model.load()

        model.select(type = Entry.Kind.income)
        val salary = model.state.form.holidayShift
        model.select(type = Entry.Kind.transfer)
        val transfer = model.state.form.holidayShift
        model.state.choose(HolidayShift.none)
        model.select(type = Entry.Kind.income)

        assertEquals(HolidayShift.previous, salary)
        assertEquals(HolidayShift.next, transfer)
        assertEquals(HolidayShift.none, model.state.form.holidayShift)
    }

    @Test
    fun savesTransferBetweenWallets() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        model.load()

        model.select(type = Entry.Kind.transfer)
        model.press(3, 0, 0, 0, 0)
        model.state.update { copy(day = 26, startDate = date("2026-09-01")) }
        val saved = model.flow.save()
        val entry = setup.database.entryList().entries.first()

        assertNotNull(saved)
        assertEquals("振替元", model.output.walletTitle)
        assertEquals(Entry.Kind.transfer, entry.type)
        assertNull(entry.categoryId)
        assertNotNull(entry.toWalletId)
        assertNotEquals(entry.walletId, entry.toWalletId)
    }

    @Test
    fun refusesSameWalletTransfer() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        model.load()

        model.select(type = Entry.Kind.transfer)
        model.press(5)
        model.state.update { copy(toWalletId = walletId) }
        val saved = model.flow.save()

        assertNull(saved)
        assertEquals("振替元と振替先を別にしてください", model.state.errorNotice.message)
        assertEquals("振替元と振替先を別にしてください", model.flow.output.saveTitle)
    }

    @Test
    fun refusesEmptyAmount() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        model.load()

        val saved = model.flow.save()

        assertNull(saved)
        assertEquals("金額を入れてください", model.state.errorNotice.message)
        assertFalse(model.flow.output.canSave)
    }

    @Test
    fun loadsExistingRecurringAndTracksChanges() = modelTest(today = "2026-10-17") { setup ->
        val recurring = setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")
        val model = setup.editModel(editingId = recurring.id)

        model.load()
        val loaded = model.flow.output.isChanged
        val title = model.flow.output.saveTitle
        model.state.update { copy(memo = "家賃と管理費") }
        val saved = model.flow.save()

        assertFalse(loaded)
        assertEquals("変更を保存", title)
        assertEquals(78000, model.output.amount)
        assertTrue(model.flow.output.isChanged)
        assertNotNull(saved)
        assertEquals(listOf("家賃と管理費"), setup.database.recurrings().map { it.memo })
        assertEquals(listOf(78000), setup.database.recurrings().map { it.amount })
    }

    @Test
    fun hidesAndDeletesExistingRecurring() = modelTest(today = "2026-10-17") { setup ->
        val recurring = setup.saveRecurring(amount = 78000, day = 27, memo = "家賃")
        val model = setup.editModel(editingId = recurring.id)
        model.load()

        val hidden = model.flow.setHidden(isHidden = true)
        val visible = setup.database.recurrings()
        val deletion = model.flow.delete()

        assertTrue(hidden)
        assertTrue(model.input.isHidden)
        assertTrue(visible.isEmpty())
        assertNotNull(deletion)
        assertTrue(setup.database.recurrings(includingHidden = true).isEmpty())
    }

    @Test
    fun failsToLoadMissingRecurring() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel(editingId = Identifier())

        model.load()

        assertEquals("固定費を読めませんでした", model.state.errorNotice.message)
    }

    @Test
    fun plansRepaymentFromLoanBalance() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.loanModel()
        val end = date("2046-09-27")

        assertTrue(model.output.isLoanRepayment)
        assertTrue(model.output.usesAutoCount)
        assertEquals(end, model.output.scheduledEndDate)
        assertEquals(240, model.output.repaymentCount)
        assertEquals(3_896_752L, model.output.plannedTotal)
        assertNull(model.output.balanceGap)
        assertEquals(end, model.output.draft.endDate)
        assertEquals(16587, model.output.draft.finalAmount)
    }

    @Test
    fun leavesRemainderForLastPaymentWhenCountIsLonger() =
        modelTest(today = "2026-10-17") { setup ->
            val model = setup.loanModel()

            model.prepareCount()
            model.pressCount(AmountCalculator.Key.Delete)
            model.pressCount(AmountCalculator.Key.Digit(1))

            assertFalse(model.output.usesAutoCount)
            assertEquals(241, model.output.repaymentCount)
            assertEquals(352, model.output.draft.finalAmount)
            assertNull(model.output.balanceGap)
        }

    @Test
    fun showsGapWhenCountIsShort() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.loanModel()

        model.prepareCount()
        model.pressCount(AmountCalculator.Key.Delete)
        model.pressCount(AmountCalculator.Key.Delete)
        model.pressCount(AmountCalculator.Key.Digit(3))
        model.pressCount(AmountCalculator.Key.Digit(9))
        val count = model.output.repaymentCount
        val finalAmount = model.output.draft.finalAmount
        val gap = model.output.balanceGap
        model.state.useAutoCount()

        assertEquals(239, count)
        assertEquals(0, finalAmount)
        assertEquals(-16587L, gap)
        assertEquals(240, model.output.repaymentCount)
        assertNull(model.output.balanceGap)
    }

    @Test
    fun usesClosingDayOnlyForCardTransfer() = modelTest(today = "2026-10-17") { setup ->
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        val cash = setup.options().wallets[0]
        val model = setup.editModel(type = Entry.Kind.transfer)
        model.load()

        model.state.update { copy(toWalletId = card.id, closingDay = 15) }
        val isCardBill = model.output.isCardBill
        val closing = model.output.draft.closingDay
        model.state.update { copy(toWalletId = cash.id) }

        assertTrue(isCardBill)
        assertEquals(15, closing)
        assertFalse(model.output.isCardBill)
        assertNull(model.output.draft.closingDay)
    }

    private fun RecurringEditModel.press(vararg digits: Int) {
        for (digit in digits) {
            state.press(AmountCalculator.Key.Digit(digit))
        }
    }

    private fun ModelTestSetup.editModel(
        type: Entry.Kind = Entry.Kind.expense,
        editingId: Identifier<Recurring>? = null,
        permission: NotificationPermission = NotificationPermission.allowed,
    ) = RecurringEditModel(
        parts = parts,
        today = today,
        type = type,
        editingId = editingId,
        permission = permission,
    )

    private suspend fun ModelTestSetup.loanModel(): RecurringEditModel {
        val loan = addWallet(kind = Wallet.Kind.loan, name = "奨学金", initialBalance = -3_896_752)
        val model = editModel(type = Entry.Kind.transfer)
        model.load()

        model.state.update { copy(toWalletId = loan.id, day = 27, startDate = date("2026-10-27")) }
        model.state.choose(HolidayShift.none)
        model.press(1, 6, 2, 3, 5)

        return model
    }
}
