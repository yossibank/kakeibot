import Core
@testable import Features
import Foundation
import FoundationModels
import Testing

@MainActor
struct ReviewCommentWriterAccuracyTests {
    @Test(.enabled(if: isModelUsable))
    func writesGroundedPoliteComments() async {
        guard #available(iOS 26.0, *) else {
            return
        }

        var hits = 0
        var lines: [String] = []

        for sample in Self.samples {
            var rejected: [String] = []

            let body = await ReviewCommentWriter.write(
                basis: sample.basis,
                scale: sample.scale,
                categories: Self.categories,
                onReject: { text in
                    rejected.append(text)
                }
            )

            guard let body else {
                lines.append("✗ 書けなかった：\(sample.basis)")
                lines += rejected.map { "  捨てた文：\($0)" }
                continue
            }

            let problems = Self.problems(in: body, for: sample)

            if problems.isEmpty {
                hits += 1
                lines.append("✓ \(body)")
            } else {
                lines.append("✗ \(problems.joined(separator: "・"))：\(body)")
            }
        }

        let rate = Double(hits) / Double(Self.samples.count)
        let report = (["\(hits)/\(Self.samples.count)"] + lines).joined(separator: "\n")

        Attachment.record(report, named: "review-comment-accuracy.txt")

        #expect(rate >= Self.minimumRate, "\(report)")
    }
}

private extension ReviewCommentWriterAccuracyTests {
    struct Sample {
        let basis: String
        let scale: ReviewPeriod.Scale
    }

    static let minimumRate = 0.8
    static let forbiddenWords = ["投資", "借入", "ローン", "保険", "すべき", "危ない", "みましょう", "```", "{", "}"]
    static let politeEndings = ["です。", "ます。", "ました。", "ません。", "でしょう。", "ましょう。", "ください。"]
    static let unitPrefixes = ["この", "次の", "前の", "今"]
    static let categories = ["食費", "交際費", "交通", "家電", "日用品", "住まい", "趣味", "コンビニ", "外食"]

    static let samples = [
        Sample(
            basis: "食費は、この月に 39,800円 使いました。いつもは 30,000円 です。\n外食の記録は、この月に 9 回でした。",
            scale: .month
        ),
        Sample(
            basis: "日用品は、この月に 9,600円 使いました。いつもは 6,400円 です。\n日用品の 1 回の平均は、この月は 2,400円 でした。",
            scale: .month
        ),
        Sample(
            basis: "交際費は、この月に 21,000円 使いました。いつもは 8,000円 です。\n交際費の記録は、この月に 6 回でした。",
            scale: .month
        ),
        Sample(
            basis: "コンビニは、この週に 4,200円 使いました。いつもは 2,100円 です。\nコンビニの記録は、この週に 6 回でした。",
            scale: .week
        ),
        Sample(
            basis: "趣味は、この年に 186,000円 使いました。いつもは 120,000円 です。\n趣味の 1 回の平均は、この年は 15,500円 でした。",
            scale: .year
        )
    ]

    static func problems(
        in body: String,
        for sample: Sample
    ) -> [String] {
        let forbidden = forbiddenWords.filter { body.contains($0) }
        let impolite = isPolite(body) ? [] : ["丁寧語で終わらない"]
        let units = wrongUnits(in: body, scale: sample.scale)

        return forbidden.map { "「\($0)」" }
            + impolite
            + units.map { "単位「\($0)」" }
    }

    static func isPolite(_ text: String) -> Bool {
        let ended = text.hasSuffix("。") ? text : text + "。"
        return politeEndings.contains { ended.hasSuffix($0) }
    }

    static func wrongUnits(
        in text: String,
        scale: ReviewPeriod.Scale
    ) -> [String] {
        let others = ReviewPeriod.Scale.allCases.filter { $0 != scale }.map(\.unitName)
        let words = others.flatMap { name in unitPrefixes.map { $0 + name } }
        return words.filter { text.contains($0) }
    }
}

private var isModelUsable: Bool {
    guard #available(iOS 26.0, *) else {
        return false
    }

    guard ProcessInfo.processInfo.environment["KAKEIBOT_MODEL_TESTS"] == "1" else {
        return false
    }

    let model = SystemLanguageModel.default
    return model.isAvailable && model.supportsLocale(Locale(identifier: "ja_JP"))
}
