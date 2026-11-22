import Foundation

public struct ReviewClosingFacts: Hashable, Sendable {
    public let verdict: Verdict?
    public let more: [String]
    public let less: [String]
    public let isGoalAchieved: Bool?
    public let recordsDaily: Bool

    public init(
        verdict: Verdict?,
        more: [String],
        less: [String],
        isGoalAchieved: Bool?,
        recordsDaily: Bool
    ) {
        self.verdict = verdict
        self.more = more
        self.less = less
        self.isGoalAchieved = isGoalAchieved
        self.recordsDaily = recordsDaily
    }
}

public extension ReviewClosingFacts {
    enum Verdict: Hashable, Sendable {
        case withinBudget
        case overBudget
        case more
        case less
        case usual
    }

    var basis: String {
        let lines = [verdict.map { "\($0)" } ?? "none", detail]
        return lines.filter { !$0.isEmpty }.joined(separator: "\n")
    }

    var detail: String {
        let goalLine: String? = switch isGoalAchieved {
        case true: "前の一手は達成しました。"
        case false: "前の一手は届きませんでした。"
        case nil: nil
        }

        let lines: [String?] = [
            more.isEmpty ? nil : "いつもより多かったカテゴリ：\(more.joined(separator: "、"))",
            less.isEmpty ? nil : "いつもより少なかったカテゴリ：\(less.joined(separator: "、"))",
            goalLine,
            recordsDaily ? "ほぼ毎日、記録が続きました。" : nil
        ]

        return lines.compactMap(\.self).joined(separator: "\n")
    }

    func opening(unit: String) -> String {
        switch verdict {
        case .withinBudget: "予算内で締めました。"
        case .overBudget: "予算を超えました。"
        case .more: "いつもより多めでした。"
        case .less: "いつもより少なめでした。"
        case .usual: "いつもどおりでした。"
        case nil: "この\(unit)を締めました。"
        }
    }

    func accepts(
        _ sentence: String,
        categories: [String]
    ) -> Bool {
        let clauses = sentence.split { "。、".contains($0) }.map(String.init)
        let named = more + less
        let strays = categories.filter { !named.contains($0) && sentence.contains($0) }
        let keepsSides = clauses.allSatisfy(keepsSides)

        return !sentence.contains { $0.isNumber }
            && !sentence.contains("予算")
            && strays.isEmpty
            && keepsSides
    }
}

private extension ReviewClosingFacts {
    static let fewerWords = ["少", "抑え", "減"]
    static let moreWords = ["多", "増", "かさ"]

    func keepsSides(_ clause: String) -> Bool {
        let hasMore = more.contains { clause.contains($0) }
        let hasLess = less.contains { clause.contains($0) }
        let saysFewer = Self.fewerWords.contains { clause.contains($0) }
        let saysMore = Self.moreWords.contains { clause.contains($0) }

        return !(hasMore && !hasLess && saysFewer)
            && !(hasLess && !hasMore && saysMore)
    }
}
