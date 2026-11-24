import DesignSystem

@MainActor
public protocol NoticeHolding: AnyObject {
    var errorNotice: ErrorNotice { get set }
}
