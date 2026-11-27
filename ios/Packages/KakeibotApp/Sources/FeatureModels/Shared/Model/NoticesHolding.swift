@MainActor
public protocol NoticesHolding: AnyObject {
    associatedtype Notices: ScreenNotices

    var notices: Notices { get }
}

public extension NoticesHolding {
    var errorNotice: ErrorNotice {
        notices.error
    }
}
