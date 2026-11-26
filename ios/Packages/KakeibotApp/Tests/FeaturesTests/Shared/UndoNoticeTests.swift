@testable import FeatureModels
import Testing
import TestSupport

@MainActor
struct UndoNoticeTests {
    @Test
    func clearsAfterDuration() async {
        let clock = ManualWait()
        let notice = UndoNotice<String>(wait: clock.wait)

        notice.show("a")
        await ObservationWait.until { clock.isSleeping }
        let shown = notice.current
        clock.advance(by: UndoNotice<String>.duration)
        await ObservationWait.until { notice.current == nil }

        #expect(shown == "a")
        #expect(notice.id == nil)
    }

    @Test
    func keepsLaterNoticeWhenEarlierTimeEnds() async {
        let clock = ManualWait()
        let notice = UndoNotice<String>(wait: clock.wait)

        notice.show("a")
        await ObservationWait.until { clock.isSleeping }
        clock.advance(by: .seconds(3))
        notice.show("b")
        await ObservationWait.until { clock.deadlines == [.seconds(7)] }
        clock.advance(by: .seconds(1))
        let kept = notice.current
        clock.advance(by: .seconds(3))
        await ObservationWait.until { notice.current == nil }

        #expect(kept == "b")
    }

    @Test
    func takesItemAndClears() {
        let notice = UndoNotice<String>(wait: ManualWait().wait)

        notice.show("a")
        let taken = notice.take()

        #expect(taken == "a")
        #expect(notice.current == nil)
        #expect(notice.take() == nil)
    }
}
