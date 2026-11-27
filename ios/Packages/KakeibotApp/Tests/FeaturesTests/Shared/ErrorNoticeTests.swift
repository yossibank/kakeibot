@testable import FeatureModels
import Testing
import TestSupport

@MainActor
struct ErrorNoticeTests {
    @Test
    func clearsAfterDuration() async {
        let clock = ManualWait()
        let notice = ErrorNotice(wait: clock.wait)

        notice.show("保存できませんでした")
        await ObservationWait.until { clock.isSleeping }
        let shown = notice.message
        clock.advance(by: ErrorNotice.duration)
        await ObservationWait.until { notice.message == nil }

        #expect(shown == "保存できませんでした")
        #expect(notice.tone == .error)
        #expect(notice.count == 1)
    }

    @Test
    func restartsTimeWhenShownAgain() async {
        let clock = ManualWait()
        let notice = ErrorNotice(wait: clock.wait)

        notice.show("a")
        await ObservationWait.until { clock.isSleeping }
        clock.advance(by: .seconds(4))
        notice.inform("b")
        await ObservationWait.until { clock.deadlines == [.seconds(10)] }
        clock.advance(by: .seconds(2))
        let kept = notice.message
        clock.advance(by: .seconds(4))
        await ObservationWait.until { notice.message == nil }

        #expect(kept == "b")
        #expect(notice.tone == .info)
        #expect(notice.count == 2)
    }

    @Test
    func clearsOnRequest() async {
        let clock = ManualWait()
        let notice = ErrorNotice(wait: clock.wait)

        notice.show("a")
        await ObservationWait.until { clock.isSleeping }
        notice.clear()
        await ObservationWait.until { !clock.isSleeping }

        #expect(notice.message == nil)
        #expect(notice.count == 1)
    }
}
