package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.featuremodels.support.ManualWait
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class UndoNoticeTest {
    @Test
    fun clearsAfterDuration() {
        val clock = ManualWait()
        val notice = UndoNotice<String>(clock.wait)

        notice.show("a")
        val shown = notice.current
        val isSleeping = clock.isSleeping
        clock.advance(by = UndoNotice.duration)

        assertEquals("a", shown)
        assertTrue(isSleeping)
        assertNull(notice.current)
    }

    @Test
    fun keepsLaterNoticeWhenEarlierTimeEnds() {
        val clock = ManualWait()
        val notice = UndoNotice<String>(clock.wait)

        notice.show("a")
        clock.advance(by = 3.seconds)
        notice.show("b")
        clock.advance(by = 1.seconds)
        val kept = notice.current
        clock.advance(by = 3.seconds)

        assertEquals("b", kept)
        assertNull(notice.current)
    }

    @Test
    fun takesItemAndClears() {
        val notice = UndoNotice<String>(ManualWait().wait)

        notice.show("a")
        val taken = notice.take()

        assertEquals("a", taken)
        assertNull(notice.current)
        assertNull(notice.take())
    }
}
