import Foundation

extension ReceiptLine {
    static func normalized(_ text: String) -> String {
        let characters = text.map { halfwidth[$0] ?? $0 }

        return String(characters)
            .replacing(#/(\d)\.(\d{3})(?!\d)/#) { "\($0.output.1),\($0.output.2)" }
            .trimmingCharacters(in: .whitespaces)
    }

    static func kind(of text: String) -> Kind {
        let words = text.filter { !$0.isWhitespace }
        let letters = text.lowercased().filter(\.isLetter)

        if let price = price(in: text) {
            return .item(price)
        }

        if letters.isEmpty, let amount = amount(in: text), amount.value < 0 {
            return .discount(name: "", amount: amount.value)
        }

        if letters.isEmpty || isTitle(letters) {
            return .heading(isTitle: !letters.isEmpty)
        }

        if headingWords.contains(where: letters.contains), amount(in: text) == nil {
            return .heading(isTitle: false)
        }

        if text.firstMatch(of: serialPattern) != nil {
            return .skip
        }

        if text.firstMatch(of: codePattern) != nil, amount(in: text) == nil {
            return .code(isReduced: text.contains(where: reducedMarks.contains))
        }

        guard words.contains(where: { !$0.isNumber && !numberJoints.contains($0) }) else {
            return .skip
        }

        if let quantity = quantity(in: text) {
            return quantity.unit > 0 ? .quantity(quantity) : .skip
        }

        let amount = amount(in: text)

        if totalWords.contains(where: words.contains), !words.contains("小計"),
           !words.contains("点数") {
            return amount.map { .total($0.value) } ?? .skip
        }

        if subtotalWords.contains(where: words.contains) {
            return amount.map { .subtotal($0.value) } ?? .skip
        }

        if let base = text.firstMatch(of: taxBasePattern),
           let rate = EntryItem.TaxRate(rawValue: Int(base.rate) ?? 0),
           let value = Int(base.base.filter(\.isNumber)) {
            return .taxBase(rate: rate, amount: value)
        }

        if let amount, isTax(words) {
            return .tax(
                amount.value,
                isExclusive: !["内", "うち", "(", "（"].contains(where: words.contains)
            )
        }

        if stopWords.contains(where: words.contains) {
            return .stop
        }

        let bare = itemWords.reduce(text.replacing(taxNotePattern, with: "")) {
            $0.replacing($1, with: "")
        }

        guard !skipWords.contains(where: bare.filter { !$0.isWhitespace }.contains) else {
            return .skip
        }

        guard let amount else {
            return .text(text)
        }

        if discountWords.contains(where: words.contains) || amount.value < 0 {
            return .discount(name: itemName(amount.name), amount: -abs(amount.value))
        }

        guard
            amount.value != 0,
            isNameLike(itemName(amount.name))
        else {
            return .skip
        }

        return .item(amount)
    }

    static func isTitle(_ letters: String) -> Bool {
        titleWords.contains(letters) || (letters.count == 3 && letters.hasPrefix("領収"))
    }

    static func isTax(_ words: String) -> Bool {
        words.contains("消費税") || words.contains("税額") || words.contains("外税")
            || (words.contains("外") && words.contains("%"))
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
