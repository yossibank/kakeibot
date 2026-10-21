import Foundation

public extension ExportV1.Tables {
    func csv() -> Data {
        let rows = [Self.csvHeader] + sortedEntries.map(row)

        let text = rows
            .map { $0.map(Self.escape).joined(separator: ",") }
            .map { $0 + "\r\n" }
            .joined()

        return Data(Self.byteOrderMark + text.utf8)
    }
}

private extension ExportV1.Tables {
    static let csvHeader = [
        "日付", "種類", "金額", "カテゴリ", "タグ", "財布", "振替先", "メモ"
    ]

    static let byteOrderMark: [UInt8] = [0xEF, 0xBB, 0xBF]

    var sortedEntries: [Entry] {
        entries.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.id.description < rhs.id.description
        }
    }

    static func escape(_ field: String) -> String {
        let needsQuotes = field.contains { "\",\r\n".contains($0) }

        guard needsQuotes else {
            return field
        }

        let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(doubled)\""
    }

    static func kindTitle(_ kind: Entry.Kind) -> String {
        switch kind {
        case .expense: "支出"
        case .income: "収入"
        case .transfer: "振替"
        }
    }

    func row(_ entry: Entry) -> [String] {
        let category = categories.first { $0.id == entry.categoryId }
        let tag = tags.first { $0.id == entry.tagId }
        let wallet = wallets.first { $0.id == entry.walletId }
        let toWallet = wallets.first { $0.id == entry.toWalletId }

        return [
            entry.date.description,
            Self.kindTitle(entry.type),
            String(entry.amount),
            category?.name ?? "",
            tag?.name ?? "",
            wallet?.name ?? "",
            toWallet?.name ?? "",
            entry.memo ?? ""
        ]
    }
}
