import Core
import Store

public extension HomeModel.Output {
    func title(of recurring: Recurring) -> String {
        input.list.value?.title(of: recurring) ?? HomeModel.recurringTitle
    }

    func place(of recurring: Recurring) -> String? {
        input.list.value?.place(of: recurring)
    }

    func walletName(of recurring: Recurring) -> String? {
        input.list.value?.wallets[recurring.walletId]?.name
    }

    func icon(of recurring: Recurring) -> Icon? {
        input.list.value?.icon(of: recurring)
    }

    func icon(for template: EntryTemplate) -> Icon? {
        input.list.value?.icon(for: template)
    }
}
