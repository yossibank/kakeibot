import Observation

@MainActor
@Observable
public final class NoticeState: NoticeHolding {
    public let errorNotice: ErrorNotice

    public init(wait: ScreenWait) {
        self.errorNotice = ErrorNotice(wait: wait)
    }
}
