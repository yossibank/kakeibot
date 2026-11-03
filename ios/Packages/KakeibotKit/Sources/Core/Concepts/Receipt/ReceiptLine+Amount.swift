import Foundation

extension ReceiptLine {
    static func price(in text: String) -> Amount? {
        guard
            let match = text.firstMatch(of: pricePattern),
            let unit = Int(match.unit.filter(\.isNumber))
        else {
            return nil
        }

        let total = match.amount.flatMap { Int($0.filter(\.isNumber)) }
        let count = match.count.flatMap { Int($0) } ?? 1

        guard
            match.prefix != nil || total != nil,
            unit > 0
        else {
            return nil
        }

        let value = total ?? unit
        let isCounted = count > 0 && unit * count == value

        guard isCounted || total == nil || unit == value else {
            return nil
        }

        return Amount(
            name: "",
            value: value,
            count: isCounted ? count : 1,
            isIncluded: match.prefix?.hasPrefix("内") ?? false
        )
    }

    static func amount(in text: String) -> Amount? {
        guard let match = text.firstMatch(of: amountPattern) else {
            return nil
        }

        let start = match.sign?.startIndex ?? match.number.startIndex
        let before = start > text.startIndex ? text[text.index(before: start)] : nil
        let digits = match.number.filter(\.isNumber)

        guard
            !(before?.isNumber ?? false),
            !numberJoints.contains(before ?? " "),
            !amountBlockers.contains(before ?? " "),
            !(before.map { $0.isASCII && $0.isLetter } ?? false),
            digits.count <= maxDigits,
            let number = Int(digits),
            number >= minMarkedAmount || !match.mark.contains(where: \.isLetter)
        else {
            return nil
        }

        let name = text[..<match.range.lowerBound].trimmingCharacters(in: .whitespaces)
        let value = match.sign == nil ? number : -number
        var amount = columns(of: name, value: value) ?? Amount(name: name, value: value)

        amount.isReduced = match.mark.contains(where: reducedMarks.contains)
            || name.firstMatch(of: leadingMarkPattern) != nil

        return amount
    }

    static func columns(
        of name: String,
        value: Int
    ) -> Amount? {
        if let match = name.firstMatch(of: columnsPattern),
           let count = Int(match.count),
           let unit = Int(match.unit.filter(\.isNumber)),
           count > 0,
           count * unit == value {
            return Amount(
                name: String(match.name).trimmingCharacters(in: .whitespaces),
                value: value,
                count: count
            )
        }

        return misreadColumns(of: name, value: value)
    }

    static func misreadColumns(
        of name: String,
        value: Int
    ) -> Amount? {
        var tokens = name.split(separator: " ").map(String.init)

        guard
            value > 0,
            let unitToken = tokens.popLast()
        else {
            return nil
        }

        let parts = unitToken.split(
            separator: "@",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )

        let gluedCount = parts.count == 2 ? Int(parts[0]) : nil
        let units = unitCandidates(of: String(parts.last ?? ""))

        let countToken = tokens.last.flatMap { token in
            token.firstMatch(of: countTokenPattern).flatMap { Int($0.output.1) }
        }

        let counts = [gluedCount, countToken ?? 1].compactMap(\.self)

        guard
            let count = counts.first(where: { count in
                count > 0 && value % count == 0 && units.contains(value / count)
            })
        else {
            return nil
        }

        if countToken != nil {
            tokens.removeLast()
        }

        let rest = tokens.joined(separator: " ")

        guard isNameLike(itemName(rest)) else {
            return nil
        }

        return Amount(name: rest, value: value, count: count)
    }

    static func unitCandidates(of token: String) -> [Int] {
        let digits = String(token.drop { !$0.isNumber }).replacing(",", with: "")

        guard
            digits.allSatisfy(\.isNumber),
            let unit = Int(digits)
        else {
            return []
        }

        let isMisreadMark = digits.count > 1 && misreadMarks.contains(digits.first ?? " ")

        return isMisreadMark ? [unit, Int(digits.dropFirst()) ?? unit] : [unit]
    }

    static func quantity(in text: String) -> Quantity? {
        if let match = text.firstMatch(of: unitFirstPattern),
           let count = Int(match.count),
           let unit = Int(match.unit.filter(\.isNumber)),
           count > 0 {
            return Quantity(count: count, unit: unit, isUnitFirst: true)
        }

        if let match = text.firstMatch(of: quantityPattern),
           let count = Int(match.count),
           let unit = Int(match.unit.filter(\.isNumber)),
           count > 0 {
            return Quantity(count: count, unit: unit, isUnitFirst: false)
        }

        return nil
    }
}
