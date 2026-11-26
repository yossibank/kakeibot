import Core

public extension AssetsModel.OutlookItem {
    enum Source: Hashable, Sendable {
        case plan(Entry.ID)
        case recurring(Recurring.ID, LocalDate)
    }
}
