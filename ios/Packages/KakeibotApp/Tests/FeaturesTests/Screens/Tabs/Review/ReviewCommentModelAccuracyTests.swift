import Core
@testable import Features
import Foundation
import FoundationModels
import Testing

@MainActor
struct ReviewCommentModelAccuracyTests {
    @Test(.enabled(if: isModelUsable))
    func writesGroundedPoliteComments() async {
        guard #available(iOS 26.0, *) else {
            return
        }

        var hits = 0
        var lines: [String] = []

        for sample in Self.samples {
            var rejected: [String] = []

            let body = await ReviewCommentModel.write(
                basis: sample.basis,
                scale: sample.scale,
                categories: Self.categories,
                isCurrent: sample.isCurrent,
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

private extension ReviewCommentModelAccuracyTests {
    struct Sample {
        let basis: String
        let scale: ReviewPeriod.Scale
        let isCurrent: Bool
    }

    static let minimumRate = 0.8
    static let forbiddenWords = ["投資", "借入", "ローン", "保険", "すべき", "危ない", "みましょう", "```", "{", "}"]
    static let politeEndings = ["です。", "ます。", "ました。", "ません。", "でしょう。", "ましょう。", "ください。"]
    static let unitPrefixes = ["この", "次の", "前の", "今"]
    static let praiseWords = ["良いこと", "良い変化", "素晴らしい", "順調"]
    static let labelWords = ["良い点：", "気を付けたい点：", "事実："]
    static let categories = ["食費", "交際費", "交通", "家電", "日用品", "住まい", "趣味"]

    static let samples = [
        Sample(
            basis: "気を付けたい点：食費は、月の 60% が過ぎたところで、予算の 97% を使っています。予算に収めるには、残りの 12 日を 1 日 150円 にします。",
            scale: .month,
            isCurrent: true
        ),
        Sample(
            basis: "気を付けたい点：交際費が、前の月の 8,000円 から 21,000円 に増えています（162% 増）。\n良い点：交通が、前の月の 26,100円 から 21,800円 に減っています（16% 減）。",
            scale: .month,
            isCurrent: false
        ),
        Sample(
            basis: "気を付けたい点：収入の 150,000円 より、支出が 32,400円 多くなっています。",
            scale: .month,
            isCurrent: true
        ),
        Sample(
            basis: "気を付けたい点：家電の 1 回の出費 48,000円 が、支出の 26% を占めています。",
            scale: .year,
            isCurrent: false
        ),
        Sample(
            basis: "良い点：収入の 265,000円 から、82,600円 残せました。",
            scale: .month,
            isCurrent: false
        ),
        Sample(
            basis: "良い点：予算のあるカテゴリは、どれも週の 40% のペースの内に収まっています。",
            scale: .week,
            isCurrent: true
        ),
        Sample(
            basis: "事実：支出は 182,400円 です。前の月より 19,500円 多いです。",
            scale: .month,
            isCurrent: false
        )
    ]

    static func problems(
        in body: String,
        for sample: Sample
    ) -> [String] {
        let forbidden = forbiddenWords.filter { body.contains($0) }
        let impolite = isPolite(body) ? [] : ["丁寧語で終わらない"]
        let units = wrongUnits(in: body, scale: sample.scale)
        let hasGood = sample.basis.contains("良い点：")
        let praise = hasGood ? [] : praiseWords.filter { body.contains($0) }
        let labels = labelWords.filter { body.contains($0) }

        return forbidden.map { "「\($0)」" }
            + impolite
            + units.map { "単位「\($0)」" }
            + praise.map { "褒め違い「\($0)」" }
            + labels.map { "印「\($0)」" }
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
