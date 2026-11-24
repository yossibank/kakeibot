import DesignSystem
import Observation

@MainActor
@Observable
public final class NoticeState: NoticeHolding {
    public var errorNotice = ErrorNotice()

    public init() {}
}
