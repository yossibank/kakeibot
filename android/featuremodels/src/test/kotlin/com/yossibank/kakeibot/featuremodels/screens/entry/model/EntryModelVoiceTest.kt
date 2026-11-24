package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.support.modelTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EntryModelVoiceTest {
    @Test
    fun appliesSpokenFieldsAndUndoesThem() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val wallet = model.output.wallets.last()

        val reading = model.output.voiceReading(
            text = "昨日コンビニで980円、${wallet.name}で",
            today = setup.today,
        )
        val undo = model.apply(reading)
        val amount = model.output.amount
        val date = model.state.form.date
        val walletId = model.state.form.walletId
        val store = model.state.store
        val fromVoice =
            listOf(
                model.output.isDateFromVoice,
                model.output.isWalletFromVoice,
                model.output.isMemoFromVoice,
            )
        model.state.undo(undo)

        assertEquals(980, amount)
        assertEquals(setup.today.adding(days = -1), date)
        assertEquals(wallet.id, walletId)
        assertEquals("コンビニ", store)
        assertEquals(listOf(true, true, true), fromVoice)
        assertEquals(EntryModel.Field.Amount, model.state.field)
        assertEquals(0, model.output.amount)
        assertEquals(setup.today, model.state.form.date)
        assertEquals("", model.state.form.memo)
        assertFalse(model.output.isDateFromVoice)
    }

    @Test
    fun keepsAmountWhenSpokenAmountIsMissing() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)

        model.apply(model.output.voiceReading(text = "昨日のコンビニ", today = setup.today))

        assertEquals(5, model.output.amount)
        assertEquals(setup.today.adding(days = -1), model.state.form.date)
    }

    @Test
    fun hintsNamesForRecognizer() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, memo = "コンビニ\n特売")
        val model = setup.loadedModel()

        val hints = model.output.voiceHints

        assertTrue("食費" in hints)
        assertTrue("財布" in hints)
        assertTrue("コンビニ" in hints)
        assertFalse("特売" in hints)
        assertFalse(model.output.showsVoice)
    }
}
