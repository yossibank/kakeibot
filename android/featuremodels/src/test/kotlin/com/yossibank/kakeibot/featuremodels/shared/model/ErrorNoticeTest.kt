package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.featuremodels.support.ManualWait
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class ErrorNoticeTest {
    @Test
    fun clearsAfterDuration() {
        val clock = ManualWait()
        val notice = ErrorNotice(clock.wait)

        notice.show("保存できませんでした")
        val shown = notice.message
        val isSleeping = clock.isSleeping
        clock.advance(by = ErrorNotice.duration)

        assertEquals("保存できませんでした", shown)
        assertTrue(isSleeping)
        assertEquals("", notice.message)
        assertEquals(ErrorNotice.Tone.error, notice.tone)
        assertEquals(1, notice.count)
    }

    @Test
    fun restartsTimeWhenShownAgain() {
        val clock = ManualWait()
        val notice = ErrorNotice(clock.wait)

        notice.show("a")
        clock.advance(by = 4.seconds)
        notice.inform("b")
        clock.advance(by = 2.seconds)
        val kept = notice.message
        clock.advance(by = 4.seconds)

        assertEquals("b", kept)
        assertEquals("", notice.message)
        assertEquals(ErrorNotice.Tone.info, notice.tone)
        assertEquals(2, notice.count)
    }

    @Test
    fun clearsOnRequest() {
        val clock = ManualWait()
        val notice = ErrorNotice(clock.wait)

        notice.show("a")
        notice.clear()

        assertEquals("", notice.message)
        assertEquals(1, notice.count)
        assertFalse(clock.isSleeping)
    }
}
