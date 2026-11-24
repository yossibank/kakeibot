import Core

public extension AssetsModel {
    struct UpcomingBill: Equatable, Sendable {
        public let bill: CardBill
        public let title: String
        public let icon: Icon?
        public let source: String?
        public let movedIn: [EntryRowItem]
        public let movedOut: [EntryRowItem]
    }
}

extension AssetsModel.UpcomingBill: Identifiable {
    public var id: Recurring.ID {
        bill.recurring.id
    }
}
