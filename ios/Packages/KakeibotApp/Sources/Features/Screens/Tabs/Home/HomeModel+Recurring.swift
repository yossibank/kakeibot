import Core
import Store

public extension HomeModel {
    func title(of recurring: Recurring) -> String {
        list?.title(of: recurring) ?? Self.recurringTitle
    }

    func place(of recurring: Recurring) -> String? {
        list?.place(of: recurring)
    }

    func walletName(of recurring: Recurring) -> String? {
        list?.wallets[recurring.walletId]?.name
    }

    func icon(of recurring: Recurring) -> Icon? {
        list?.icon(of: recurring)
    }

    func icon(for template: EntryTemplate) -> Icon? {
        list?.icon(for: template)
    }
}

extension HomeModel {
    static let recurringTitle = "固定費"
}
