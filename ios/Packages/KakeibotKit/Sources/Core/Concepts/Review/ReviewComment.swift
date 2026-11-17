import Foundation

public struct ReviewComment: Codable, Hashable, Sendable {
    public let period: String

    public var body: String
    public var suggestion: String
    public var basis: String
    public var createdAt: Date

    public init(
        period: String,
        body: String,
        suggestion: String,
        basis: String,
        createdAt: Date
    ) {
        self.period = period
        self.body = body
        self.suggestion = suggestion
        self.basis = basis
        self.createdAt = createdAt
    }
}

public extension ReviewComment {
    static let minimumEntries = 5

    static func cleaned(_ text: String) -> String {
        let end = cutMarks.compactMap { text.range(of: $0)?.lowerBound }.min() ?? text.endIndex
        let kept = text[..<end]
        return kept.trimmingCharacters(in: trimmed)
    }

    static func droppingAdvice(_ text: String) -> String {
        let sentences = text.split(separator: "。", omittingEmptySubsequences: true)

        let kept = sentences.filter { sentence in
            let body = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            return !adviceEndings.contains { body.hasSuffix($0) }
        }

        return kept.map { "\($0)。" }.joined()
    }

    static func basis(of insights: [ReviewInsight]) -> String {
        insights.map(\.labeledFact).joined(separator: "\n")
    }

    static func isGrounded(
        _ text: String,
        in basis: String,
        categories: [String]
    ) -> Bool {
        let allowed = numbers(in: basis).union([1])
        let named = categories.filter { !$0.isEmpty && text.contains($0) }

        return numbers(in: text).isSubset(of: allowed)
            && named.allSatisfy { basis.contains($0) }
    }

    func needsRewrite(
        basis: String,
        isCurrent: Bool,
        today: Date,
        calendar: Calendar
    ) -> Bool {
        guard basis != self.basis else {
            return false
        }

        guard isCurrent else {
            return true
        }

        return !calendar.isDate(createdAt, inSameDayAs: today)
    }
}

public extension ReviewPeriod {
    var commentKey: String {
        "\(scale.rawValue):\(range.lowerBound)"
    }
}

public extension ReviewPeriod.Scale {
    var unitName: String {
        switch self {
        case .week: "週"
        case .month: "月"
        case .year: "年"
        }
    }
}

private extension ReviewComment {
    static let adviceEndings = ["ましょう", "ください"]
    static let cutMarks = ["```", "」}", "\"}", "}", "{"]
    static let trimmed = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet(charactersIn: "「」\""))

    static func numbers(in text: String) -> Set<Int> {
        let matches = text.matches(of: #/[0-9０-９][0-9０-９,，]*/#)

        let values = matches.compactMap { match in
            let digits = match.output.compactMap(\.wholeNumberValue)
            return digits.isEmpty ? nil : digits.reduce(0) { $0 * 10 + $1 }
        }

        return Set(values)
    }
}
