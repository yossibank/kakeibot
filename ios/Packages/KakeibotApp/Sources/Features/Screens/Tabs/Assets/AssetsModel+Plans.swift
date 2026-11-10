import Core
import Store

public extension AssetsModel {
    struct Plan: Equatable, Identifiable {
        public let id: Entry.ID
        public let date: LocalDate
        public let title: String
        public let wallet: String?
        public let change: Int
    }
}

extension AssetsModel {
    func makePlans(in wallets: [Wallet]) -> [Plan] {
        guard let list else {
            return []
        }

        return list.entries
            .filter { $0.date > today }
            .sorted { $0.date < $1.date }
            .compactMap { entry in
                let change = entry.availableChange(in: wallets)

                guard change != 0 else {
                    return nil
                }

                return Plan(
                    id: entry.id,
                    date: entry.date,
                    title: list.title(of: entry),
                    wallet: Self.walletText(of: entry, in: list),
                    change: change
                )
            }
    }
}

private extension AssetsModel {
    static func walletText(
        of entry: Entry,
        in list: EntryList
    ) -> String? {
        let source = list.wallets[entry.walletId]?.name

        guard
            let source,
            let destination = entry.toWalletId.flatMap({ list.wallets[$0]?.name })
        else {
            return source
        }

        return "\(source) → \(destination)"
    }
}
