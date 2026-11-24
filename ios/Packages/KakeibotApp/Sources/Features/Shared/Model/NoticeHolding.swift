import DesignSystem

@MainActor
protocol NoticeHolding: AnyObject {
    var errorNotice: ErrorNotice { get set }
}
