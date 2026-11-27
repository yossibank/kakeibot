import Observation

@MainActor
@Observable
public final class NoticeState: NoticesHolding {
    public let notices: Notices

    public init(wait: ScreenWait) {
        self.notices = Notices(wait: wait)
    }
}

public extension NoticeState {
    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }
}
