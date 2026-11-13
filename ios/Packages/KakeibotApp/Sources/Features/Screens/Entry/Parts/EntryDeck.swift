import Core

enum EntryDeck: Hashable {
    case category
    case transfer
    case amount
    case fee
    case wallet(EntryWalletSheet.Role)
    case date

    static func fields(for type: Entry.Kind) -> [Self] {
        switch type {
        case .transfer: [.transfer, .fee, .date, .amount]
        case .expense, .income: [.category, .wallet(.source), .date, .amount]
        }
    }

    static func start(for type: Entry.Kind) -> Self {
        type == .transfer ? .transfer : .category
    }

    func field(for type: Entry.Kind) -> Self {
        switch (self, type) {
        case (.wallet, .transfer): .transfer
        default: self
        }
    }

    func order(for type: Entry.Kind) -> Int {
        let target = field(for: type)
        return Self.fields(for: type).firstIndex(of: target) ?? 0
    }
}
