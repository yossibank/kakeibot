import Foundation

public extension ExportV1.Tables {
    func csv() -> Data {
        let rows = [Self.csvHeader] + sortedRows.map(\.fields)

        let text = rows
            .map { $0.map(Self.escape).joined(separator: ",") }
            .map { $0 + "\r\n" }
            .joined()

        let bytes = Self.byteOrderMark + text.utf8

        return Data(bytes)
    }
}

private extension ExportV1.Tables {
    struct CSVRow {
        let date: LocalDate
        let createdAt: Date
        let id: String
        let fields: [String]
    }

    static let csvHeader = [
        "日付", "種類", "金額", "カテゴリ", "タグ", "財布", "振替先", "メモ"
    ]

    static let adjustmentTitle = "調整"
    static let byteOrderMark: [UInt8] = [0xEF, 0xBB, 0xBF]
    static let formulaPrefixes: Set<Character> = ["=", "+", "-", "@"]
    static let quotedScalars: Set<Unicode.Scalar> = ["\"", ",", "\r", "\n"]

    var sortedRows: [CSVRow] {
        let rows = entries.map(row) + adjustments.map(row)

        return rows.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.id < rhs.id
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
        let needsQuotes = field.unicodeScalars.contains { quotedScalars.contains($0) }

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

    func walletName(_ id: Wallet.ID?) -> String {
        wallets.first { $0.id == id }?.name ?? ""
    }

    func row(_ entry: Entry) -> CSVRow {
        let categoryName = categories.first { $0.id == entry.categoryId }?.name ?? ""
        let tagName = tags.first { $0.id == entry.tagId }?.name ?? ""

        let fields = [
            entry.date.description,
            Self.kindTitle(entry.type),
            String(entry.amount),
            Self.text(categoryName),
            Self.text(tagName),
            Self.text(walletName(entry.walletId)),
            Self.text(walletName(entry.toWalletId)),
            Self.text(entry.memo ?? "")
        ]

        return CSVRow(
            date: entry.date,
            createdAt: entry.createdAt,
            id: entry.id.description,
            fields: fields
        )
    }

    func row(_ adjustment: Adjustment) -> CSVRow {
        let fields = [
            adjustment.date.description,
            Self.adjustmentTitle,
            String(adjustment.amount),
            "",
            "",
            Self.text(walletName(adjustment.walletId)),
            "",
            ""
        ]

        return CSVRow(
            date: adjustment.date,
            createdAt: adjustment.createdAt,
            id: adjustment.id.description,
            fields: fields
        )
    }
}
