import Core
import DesignSystem
import SwiftUI

struct EntryRecentTransfers: View {
    let model: EntryModel
    let transfers: [Entry]
    let onUse: (Entry) -> Void

    var body: some View {
        EntryRecentRow(title: "最近の振替") {
            EntryRecentLine {
                ForEach(transfers) { transfer in
                    EntryRecentCard(
                        title: model.wallet(transfer.walletId)?.name ?? "",
                        amount: transfer.amount,
                        detail: destination(transfer),
                        isPinned: false,
                        onUse: {
                            onUse(transfer)
                        },
                        mark: {
                            IconTile(sourceIcon(transfer), size: 32)
                        }
                    )
                }
            }
        }
    }
}

private extension EntryRecentTransfers {
    func destination(_ transfer: Entry) -> String {
        let name = model.wallet(transfer.toWalletId)?.name ?? ""
        return "→ \(name)"
    }

    func sourceIcon(_ transfer: Entry) -> Icon? {
        model.wallet(transfer.walletId).flatMap(model.icon(for:))
    }
}
