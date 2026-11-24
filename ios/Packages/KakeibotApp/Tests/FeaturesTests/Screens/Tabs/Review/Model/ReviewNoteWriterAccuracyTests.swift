import Core
@testable import FeatureModels
@testable import Features
import Foundation
import FoundationModels
import Testing

@MainActor
struct ReviewNoteWriterAccuracyTests {
    @Test(.enabled(if: isNoteModelUsable))
    func writesSummariesThatMatchTheFacts() async {
        guard #available(iOS 26.0, *) else {
            return
        }

        var lines: [String] = []

        for facts in Self.samples {
            var rejected: [String] = []

            let body = await ReviewNoteWriter.summary(
                facts: facts,
                scale: .month,
                categories: Self.categories,
                onReject: { text in
                    rejected.append(text)
                }
            )

            lines.append(Self.line(body, facts: facts))

            if body == nil {
                lines += rejected.map { "  捨てた文：\($0)" }
            }
        }

        let hits = lines.count { $0.hasPrefix("✓") }
        let rate = Double(hits) / Double(Self.samples.count)
        let report = (["\(hits)/\(Self.samples.count)"] + lines).joined(separator: "\n")

        Attachment.record(report, named: "review-summary-accuracy.txt")

        #expect(rate >= Self.minimumRate, "\(report)")
    }
}

private extension ReviewNoteWriterAccuracyTests {
    static let minimumRate = 0.8
    static let forbiddenWords = ["投資", "借入", "ローン", "保険", "すべき", "危ない", "みましょう", "```", "{", "}"]
    static let politeEndings = ["です。", "ます。", "ました。", "でした。", "ません。", "でしょう。"]
    static let categories = ["食費", "光熱費", "交通", "日用品", "医療", "交際", "衣服"]

    static let samples = [
        ReviewClosingFacts(
            verdict: .withinBudget,
            more: ["食費"],
            less: ["日用品"],
            isGoalAchieved: true,
            recordsDaily: true
        ),
        ReviewClosingFacts(
            verdict: .overBudget,
            more: ["交際", "衣服"],
            less: [],
            isGoalAchieved: false,
            recordsDaily: false
        ),
        ReviewClosingFacts(
            verdict: .less,
            more: [],
            less: ["食費", "交通"],
            isGoalAchieved: nil,
            recordsDaily: false
        ),
        ReviewClosingFacts(
            verdict: .usual,
            more: ["医療"],
            less: ["交際"],
            isGoalAchieved: nil,
            recordsDaily: false
        ),
        ReviewClosingFacts(
            verdict: .withinBudget,
            more: [],
            less: [],
            isGoalAchieved: nil,
            recordsDaily: true
        ),
        ReviewClosingFacts(
            verdict: .overBudget,
            more: ["光熱費"],
            less: ["衣服"],
            isGoalAchieved: true,
            recordsDaily: true
        ),
        ReviewClosingFacts(
            verdict: .more,
            more: ["食費", "日用品"],
            less: [],
            isGoalAchieved: nil,
            recordsDaily: false
        ),
        ReviewClosingFacts(
            verdict: .withinBudget,
            more: ["医療"],
            less: ["食費", "交際"],
            isGoalAchieved: false,
            recordsDaily: false
        ),
        ReviewClosingFacts(
            verdict: .usual,
            more: [],
            less: [],
            isGoalAchieved: true,
            recordsDaily: true
        ),
        ReviewClosingFacts(
            verdict: nil,
            more: ["交通"],
            less: ["日用品"],
            isGoalAchieved: nil,
            recordsDaily: false
        )
    ]

    static func line(
        _ body: String?,
        facts: ReviewClosingFacts
    ) -> String {
        guard let body else {
            return "✗ 書けなかった：\(facts.basis.split(separator: "\n").joined(separator: " / "))"
        }

        let forbidden = forbiddenWords.filter { body.contains($0) }
        let ended = body.hasSuffix("。") ? body : body + "。"
        let isPolite = politeEndings.contains { ended.hasSuffix($0) }
        let problems = forbidden.map { "「\($0)」" } + (isPolite ? [] : ["丁寧語で終わらない"])

        return problems.isEmpty ? "✓ \(body)" : "✗ \(problems.joined(separator: "・"))：\(body)"
    }
}

private var isNoteModelUsable: Bool {
    guard #available(iOS 26.0, *) else {
        return false
    }

    guard ProcessInfo.processInfo.environment["KAKEIBOT_MODEL_TESTS"] == "1" else {
        return false
    }

    let model = SystemLanguageModel.default
    return model.isAvailable && model.supportsLocale(Locale(identifier: "ja_JP"))
}
