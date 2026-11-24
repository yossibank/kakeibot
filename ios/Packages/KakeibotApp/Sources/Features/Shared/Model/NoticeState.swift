import DesignSystem
import Observation

@MainActor
@Observable
public final class NoticeState: NoticeHolding {
    public internal(set) var errorNotice = ErrorNotice()

    public init() {}
}
