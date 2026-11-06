import Foundation

struct ReceiptLine {
    let text: String
    let kind: Kind
    let date: LocalDate?
    let amount: Amount?
    let quantity: Quantity?

    init(_ text: String) {
        let normalized = Self.normalized(text)
        let date = Self.date(in: normalized)

        self.text = normalized
        self.kind = date == nil ? Self.kind(of: normalized) : .skip
        self.date = date
        self.amount = Self.price(in: normalized) ?? Self.amount(in: normalized)
        self.quantity = Self.quantity(in: normalized)
    }
}

extension ReceiptLine {
    enum Kind: Equatable {
        case heading(isTitle: Bool)
        case code(isReduced: Bool)
        case item(Amount)
        case quantity(Quantity)
        case discount(name: String, amount: Int)
        case subtotal(Int)
        case taxBase(rate: EntryItem.TaxRate, amount: Int)
        case tax(Int, isExclusive: Bool)
        case total(Int)
        case stop
        case text(String)
        case skip
    }

    struct Quantity: Equatable {
        let count: Int
        let unit: Int
        let isUnitFirst: Bool
    }

    struct Amount: Equatable {
        var name: String
        let value: Int
        var count = 1
        var isReduced = false
        var isIncluded = false
    }

    var isNamed: Bool {
        guard case let .text(text) = kind else {
            return false
        }

        return text.filter(\.isLetter).count >= 2
            && text.firstMatch(of: Self.codePattern) == nil
            && text.firstMatch(of: Self.phonePattern) == nil
    }

    var isStoreLike: Bool {
        isNamed && !Self.addressWords.contains(where: text.contains)
    }

    var isEnd: Bool {
        switch kind {
        case .total, .stop:
            true

        default:
            false
        }
    }

    var isItemLike: Bool {
        switch kind {
        case let .item(amount):
            amount.value > 0

        case .heading(isTitle: false):
            (amount?.value ?? 0) > 0

        default:
            false
        }
    }

    var isDiscountLike: Bool {
        if case .discount = kind {
            return true
        }

        return (amount?.value ?? 0) < 0
    }

    var isReducedCode: Bool {
        kind == .code(isReduced: true)
    }

    static func itemName(_ text: String) -> String {
        var name = text
            .replacing(Self.taxNotePattern, with: "")
            .replacing(Self.leadingMarkPattern, with: "")
            .trimmingCharacters(in: Self.nameTrimmed)

        name = String(name.map { halfwidthKana[$0] ?? $0 })
            .replacing(takeOutPattern, with: "T/O ")

        return name.replacing(#/\s{2,}/#, with: " ")
    }

    static func isNameLike(_ name: String) -> Bool {
        let letters = name.filter(\.isLetter)
        return letters.count >= 2 || letters.contains { !$0.isASCII }
    }

    static func storeName(_ text: String) -> String {
        text
            .replacing(#/[（(]\s*[)）]/#, with: "")
            .replacing(#/\s{2,}/#, with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}
