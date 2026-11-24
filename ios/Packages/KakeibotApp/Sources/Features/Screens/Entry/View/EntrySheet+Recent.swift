import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension EntrySheet {
    @ViewBuilder
    var recentRow: some View {
        if model.state.type == .transfer {
            let transfers = model.output.recentTransfers

            if !transfers.isEmpty {
                EntryRecentTransfers(model: model, transfers: transfers) { transfer in
                    useTransfer(transfer)
                }
            }
        } else {
            let templates = model.output.templates
            let entries = model.output.recentEntries

            if !templates.isEmpty || !entries.isEmpty {
                EntryRecentRow(title: "よく使う") {
                    EntryRecentLines {
                        ForEach(templates) { template in
                            templateCard(template)
                        }

                        ForEach(entries) { entry in
                            recentCard(entry)
                        }
                    }
                }
            }
        }
    }
}

private extension EntrySheet {
    func templateCard(_ template: EntryTemplate) -> some View {
        let category = model.output.category(of: template)

        return EntryRecentCard(
            title: template.name,
            amount: template.amount,
            detail: detail(category: category?.name, walletId: template.walletId),
            isPinned: true,
            onUse: {
                useTemplate(template)
            },
            mark: {
                IconTile(model.output.icon(for: template), size: 32)
            }
        )
    }

    func recentCard(_ entry: Entry) -> some View {
        let category = model.output.category(of: entry)
        let memo = entry.memo.flatMap { $0.isEmpty ? nil : $0 }
        let named = memo == nil ? nil : category?.name

        return EntryRecentCard(
            title: memo ?? category?.name ?? "",
            amount: entry.amount,
            detail: detail(category: named, walletId: entry.walletId),
            isPinned: false,
            onUse: {
                useRecent(entry)
            },
            mark: {
                IconTile(category.flatMap(model.output.icon(for:)), size: 32)
            }
        )
    }

    func detail(
        category: String?,
        walletId: Wallet.ID?
    ) -> String {
        let wallet = model.output.wallet(walletId)?.name

        return [category, wallet]
            .compactMap(\.self)
            .joined(separator: "・")
    }
}
