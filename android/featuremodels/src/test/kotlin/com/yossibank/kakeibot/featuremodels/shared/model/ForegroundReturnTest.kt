package com.yossibank.kakeibot.featuremodels.shared.model

import org.junit.Test
import kotlin.test.assertEquals

class ForegroundReturnTest {
    @Test
    fun detectsForegroundAfterInactive() {
        val foreground = ForegroundReturn()

        val results = listOf(
            foreground.receive(ForegroundReturn.Phase.Inactive),
            foreground.receive(ForegroundReturn.Phase.Active),
            foreground.receive(ForegroundReturn.Phase.Background),
            foreground.receive(ForegroundReturn.Phase.Inactive),
            foreground.receive(ForegroundReturn.Phase.Active),
            foreground.receive(ForegroundReturn.Phase.Active),
        )

        assertEquals(listOf(false, false, false, false, true, false), results)
    }
}
