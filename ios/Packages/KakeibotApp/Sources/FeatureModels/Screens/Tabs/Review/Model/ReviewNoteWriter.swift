import Core
import Foundation
import FoundationModels

@available(iOS 26.0, *)
@MainActor
enum ReviewNoteWriter {
    static func summary(
        facts: ReviewClosingFacts,
        scale: ReviewPeriod.Scale,
        categories: [String],
        onReject: (String) -> Void = { _ in }
    ) async -> String? {
        let detail = facts.detail

        guard
            ReviewCommentWriter.isUsable,
            !detail.isEmpty
        else {
            return nil
        }

        for options in attempts {
            guard let raw = await respond(detail: detail, scale: scale, options: options) else {
                continue
            }

            let cleaned = ReviewComment.cleaned(raw)
            let body = ReviewComment.droppingAdvice(cleaned)
            let grounded = ReviewComment.grounded(body, in: detail, categories: categories)
            let sentence = grounded.split(separator: "。").first.map { "\($0)。" } ?? ""

            guard
                !sentence.isEmpty,
                facts.accepts(sentence, categories: categories)
            else {
                onReject(raw)
                continue
            }

            return facts.opening(unit: scale.unitName) + sentence
        }

        return nil
    }
}

@available(iOS 26.0, *)
private extension ReviewNoteWriter {
    @Generable
    struct Summary {
        @Guide(description: "締めた期間の様子を書いた 1 文の丁寧語。数字は書かない")
        var body: String
    }

    static let maximumTokens = 120

    static let attempts = [
        GenerationOptions(samplingMode: .greedy, maximumResponseTokens: maximumTokens),
        GenerationOptions(
            samplingMode: .random(probabilityThreshold: 0.9, seed: 1),
            maximumResponseTokens: maximumTokens
        ),
        GenerationOptions(
            samplingMode: .random(probabilityThreshold: 0.9, seed: 2),
            maximumResponseTokens: maximumTokens
        )
    ]

    static let instructions = """
    家計簿アプリの振り返りで、締めた期間の様子を 1 文で書く。読む人は、自分の家計を見直したい人である。
    多かったカテゴリと少なかったカテゴリがあれば、それを書く。無ければ、一手の結果か記録の続き方を書く。
    事実にあるカテゴリの名前だけを使う。事実に無い出来事・予算・数字・金額・回数・割合は書かない。
    丁寧語（です・ます）で書き、責めない。「〜すべき」「〜しましょう」のような助言は書かない。
    投資・借入・保険・クレジットカードの申し込みなど、金融の商品は勧めない。ほかの家庭とは比べない。
    例：食費が多めでしたが、日用品を抑えられています。
    """

    static func respond(
        detail: String,
        scale: ReviewPeriod.Scale,
        options: GenerationOptions
    ) async -> String? {
        let name = scale.unitName

        let prompt = """
        期間は「\(name)」と呼ぶ。ほかの単位（週・月・年）で書かない。
        事実：
        \(detail)
        """

        let session = LanguageModelSession(
            model: .default,
            instructions: instructions
        )

        let response = try? await session.respond(
            to: prompt,
            generating: Summary.self,
            options: options
        )

        return response?.content.body
    }
}
