import Foundation

public struct ReviewComment: Codable, Hashable, Sendable {
    public let period: String

    public var body: String
    public var suggestion: String
    public var basis: String
    public var createdAt: Date
    public var breakdown: ReviewBreakdown.Summary?

    public init(
        period: String,
        body: String,
        suggestion: String,
        basis: String,
        createdAt: Date,
        breakdown: ReviewBreakdown.Summary? = nil
    ) {
        self.period = period
        self.body = body
        self.suggestion = suggestion
        self.basis = basis
        self.createdAt = createdAt
        self.breakdown = breakdown
    }
}

public extension ReviewComment {
    static let minimumEntries = 5

    var increasedNumbers: Set<Int> {
        let sentences = basis.split { "。\n".contains($0) }

        let numbers = sentences
            .filter { sentence in
                Self.increaseWords.contains { sentence.contains($0) }
            }
            .reduce(into: Set<Int>()) { numbers, sentence in
                numbers.formUnion(Self.numbers(in: String(sentence)))
            }

        return numbers.filter { $0 > 1 }
    }

    static func cleaned(_ text: String) -> String {
        let end = cutMarks.compactMap { text.range(of: $0)?.lowerBound }.min() ?? text.endIndex
        let kept = text[..<end]
        return kept.trimmingCharacters(in: trimmed)
    }

    static func normalizedNumbers(_ text: String) -> String {
        let halfWidth = String(text.map { halfWidthMarks[$0] ?? $0 })

        return halfWidth.replacing(#/[0-9]+(?:,[0-9]+)+/#) { match in
            let digits = match.output.filter(\.isNumber)
            let value = Int(digits) ?? 0
            return value.formatted(.number.locale(locale))
        }
    }

    static func numbers(in text: String) -> Set<Int> {
        let matches = text.matches(of: #/[0-9０-９][0-9０-９,，]*/#)

        let values = matches.compactMap { match in
            let digits = match.output.compactMap(\.wholeNumberValue)
            return digits.isEmpty ? nil : digits.reduce(0) { $0 * 10 + $1 }
        }

        return Set(values)
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

    static func facts(
        _ insights: [ReviewInsight],
        with breakdown: ReviewBreakdown?
    ) -> [ReviewInsight] {
        guard
            let breakdown,
            let first = insights.first
        else {
            return insights
        }

        return [first] + breakdown.insights.prefix(2)
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

    static func grounded(
        _ text: String,
        in basis: String,
        categories: [String]
    ) -> String {
        let sentences = text.split(separator: "。", omittingEmptySubsequences: true)

        let kept = sentences.filter { sentence in
            isGrounded(String(sentence), in: basis, categories: categories)
        }

        return kept.map { "\($0)。" }.joined()
    }

    func needsRewrite(basis: String) -> Bool {
        basis != self.basis
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
    static let increaseWords = ["増", "上が"]
    static let cutMarks = ["```", "」}", "\"}", "}", "{"]
    static let locale = Locale(identifier: "ja_JP")
    static let trimmed = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet(charactersIn: "「」\""))

    static let halfWidthMarks: [Character: Character] = {
        let full = Array("０１２３４５６７８９，％")
        let half = Array("0123456789,%")
        return Dictionary(uniqueKeysWithValues: zip(full, half))
    }()
}
