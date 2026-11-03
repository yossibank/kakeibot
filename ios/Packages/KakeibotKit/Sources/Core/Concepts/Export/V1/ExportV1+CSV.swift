import Foundation

public extension ExportV1.Tables {
    func csv() -> Data {
        let rows = [Self.csvHeader] + sortedEntries.map(row)

        let text = rows
            .map { $0.map(Self.escape).joined(separator: ",") }
            .map { $0 + "\r\n" }
            .joined()

        let bytes = Self.byteOrderMark + text.utf8

        return Data(bytes)
    }
}

private extension ExportV1.Tables {
    static let csvHeader = [
        "日付", "種類", "金額", "カテゴリ", "タグ", "財布", "振替先", "メモ"
    ]

    static let byteOrderMark: [UInt8] = [0xEF, 0xBB, 0xBF]
    static let formulaPrefixes: Set<Character> = ["=", "+", "-", "@"]

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

    static func text(_ field: String) -> String {
        guard
            let first = field.first,
            formulaPrefixes.contains(first)
        else {
            return field
        }

        return "'" + field
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
        let categoryName = categories.first { $0.id == entry.categoryId }?.name ?? ""
        let tagName = tags.first { $0.id == entry.tagId }?.name ?? ""
        let walletName = wallets.first { $0.id == entry.walletId }?.name ?? ""
        let toWalletName = wallets.first { $0.id == entry.toWalletId }?.name ?? ""

        return [
            entry.date.description,
            Self.kindTitle(entry.type),
            String(entry.amount),
            Self.text(categoryName),
            Self.text(tagName),
            Self.text(walletName),
            Self.text(toWalletName),
            Self.text(entry.memo ?? "")
        ]
    }
}
