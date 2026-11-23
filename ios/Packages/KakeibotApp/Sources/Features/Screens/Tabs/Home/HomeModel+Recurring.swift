import Core
import Store

public extension HomeModel.Output {
    func title(of recurring: Recurring) -> String {
        input.list?.title(of: recurring) ?? HomeModel.recurringTitle
    }

    func place(of recurring: Recurring) -> String? {
        input.list?.place(of: recurring)
    }

    func walletName(of recurring: Recurring) -> String? {
        input.list?.wallets[recurring.walletId]?.name
    }

    func icon(of recurring: Recurring) -> Icon? {
        input.list?.icon(of: recurring)
    }

    func icon(for template: EntryTemplate) -> Icon? {
        input.list?.icon(for: template)
    }
}
