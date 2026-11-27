import Observation

@MainActor
@Observable
public final class ErrorNoticeState: NoticesHolding {
    public let notices: Notices

    public init(wait: ScreenWait) {
        self.notices = Notices(wait: wait)
    }
}

public extension ErrorNoticeState {
    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }
}
