import Foundation

struct ReceiptLine {
    let kind: Kind
    let date: LocalDate?

    init(_ text: String) {
        let normalized = Self.normalized(text)
        let date = Self.date(in: normalized)

        self.kind = date == nil ? Self.kind(of: normalized) : .skip
        self.date = date
    }
}

extension ReceiptLine {
    enum Kind: Equatable {
        case total(Int)
        case item(name: String, amount: Int)
        case quantity(Quantity)
        case discount(Int)
        case text(String)
        case skip
    }

    struct Quantity: Equatable {
        let count: Int
        let unit: Int
    }
}

private extension ReceiptLine {
    static let totalWords = ["合計", "お会計", "ご請求"]
    static let discountWords = ["値引", "割引", "クーポン"]

    static let skipWords = [
        "小計", "消費税", "外税", "内税", "税率", "対象", "お預", "預り", "お釣", "釣銭",
        "現金", "クレジット", "ポイント", "点数", "TEL", "電話", "領収", "レジ", "No.",
        "ありがとう"
    ]

    static let numberJoints: Set<Character> = [":", "-", "/", "."]

    static let halfwidth: [Character: Character] = [
        "０": "0", "１": "1", "２": "2", "３": "3", "４": "4",
        "５": "5", "６": "6", "７": "7", "８": "8", "９": "9",
        "，": ",", "￥": "¥", "－": "-", "−": "-", "＊": "*", "×": "x",
        "＠": "@", "　": " ", "．": ".", "／": "/", "：": ":"
    ]

    static var amountPattern: Regex<(Substring, sign: Substring?, number: Substring)> {
        #/
            (?<sign>[-△▲])?\s*¥?\s*(?<number>\d{1,3}(?:,\d{3})+|\d+)\s*円?\s*[※*軽外内非A-Za-z]{0,2}\s*$
        /#
    }

    static var quantityPattern: Regex<(Substring, count: Substring, unit: Substring)> {
        #/
            (?<count>\d+)\s*(?:コ|個|点|ｺ)?\s*[x*]\s*(?:単|@)?\s*¥?\s*(?<unit>\d{1,3}(?:,\d{3})+|\d+)
        /#
    }

    static var unitFirstPattern: Regex<(Substring, unit: Substring, count: Substring)> {
        #/
            @\s*¥?\s*(?<unit>\d{1,3}(?:,\d{3})+|\d+)\s*[x*]\s*(?<count>\d+)
        /#
    }

    static var datePattern: Regex<(Substring, year: Substring, month: Substring, day: Substring)> {
        #/
            (?<year>20\d{2})\s*[年/\-.]\s*(?<month>\d{1,2})\s*[月/\-.]\s*(?<day>\d{1,2})
        /#
    }

    static func normalized(_ text: String) -> String {
        let characters = text.map { halfwidth[$0] ?? $0 }
        return String(characters).trimmingCharacters(in: .whitespaces)
    }

    static func kind(of text: String) -> Kind {
        guard !text.isEmpty else {
            return .skip
        }

        if let quantity = quantity(in: text) {
            return .quantity(quantity)
        }

        let amount = amount(in: text)
        let words = text.filter { !$0.isWhitespace }

        if totalWords.contains(where: words.contains), !words.contains("小計") {
            return amount.map { .total($0.value) } ?? .skip
        }

        guard !skipWords.contains(where: words.contains) else {
            return .skip
        }

        guard let amount else {
            return .text(text)
        }

        if discountWords.contains(where: words.contains) || amount.value < 0 {
            return .discount(-abs(amount.value))
        }

        guard !amount.name.isEmpty else {
            return .skip
        }

        return .item(name: amount.name, amount: amount.value)
    }

    static func amount(in text: String) -> (name: String, value: Int)? {
        guard let match = text.firstMatch(of: amountPattern) else {
            return nil
        }

        let start = match.range.lowerBound
        let before = start > text.startIndex ? text[text.index(before: start)] : nil
        let digits = match.number.filter(\.isNumber)

        guard
            !(before?.isNumber ?? false),
            !numberJoints.contains(before ?? " "),
            let number = Int(digits)
        else {
            return nil
        }

        let name = text[..<match.range.lowerBound].trimmingCharacters(in: .whitespaces)
        let value = match.sign == nil ? number : -number

        return (name, value)
    }

    static func quantity(in text: String) -> Quantity? {
        if let match = text.firstMatch(of: unitFirstPattern),
           let count = Int(match.count),
           let unit = Int(match.unit.filter(\.isNumber)),
           count > 0 {
            return Quantity(count: count, unit: unit)
        }

        if let match = text.firstMatch(of: quantityPattern),
           let count = Int(match.count),
           let unit = Int(match.unit.filter(\.isNumber)),
           count > 0 {
            return Quantity(count: count, unit: unit)
        }

        return nil
    }

    static func date(in text: String) -> LocalDate? {
        guard
            let match = text.firstMatch(of: datePattern),
            let year = Int(match.year),
            let month = Int(match.month),
            let day = Int(match.day)
        else {
            return nil
        }

        return LocalDate(year: year, month: month, day: day)
    }
}
