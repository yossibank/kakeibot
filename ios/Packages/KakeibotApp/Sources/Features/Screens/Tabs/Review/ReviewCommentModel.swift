import Core
import Foundation
import FoundationModels

@available(iOS 26.0, *)
@MainActor
enum ReviewCommentModel {
    static var isUsable: Bool {
        let model = SystemLanguageModel.default
        return model.isAvailable && model.supportsLocale(locale)
    }

    static func write(
        basis: String,
        scale: ReviewPeriod.Scale,
        categories: [String],
        onReject: (String) -> Void = { _ in }
    ) async -> String? {
        guard isUsable else {
            return nil
        }

        for options in attempts {
            let attempt = await respond(
                basis: basis,
                scale: scale,
                options: options
            )

            guard let body = attempt else {
                onReject("答えが返らなかった")
                continue
            }

            let grounded = ReviewComment.grounded(
                body,
                in: basis,
                categories: categories
            )

            guard !grounded.isEmpty else {
                onReject(body)
                continue
            }

            return grounded
        }

        return nil
    }
}

@available(iOS 26.0, *)
private extension ReviewCommentModel {
    @Generable
    struct Comment {
        @Guide(description: "次の目標を決めた理由。1〜2 文の丁寧語")
        var body: String
    }

    static let locale = Locale(identifier: "ja_JP")
    static let maximumTokens = 160

    static let attempts = [
        GenerationOptions(samplingMode: .greedy, maximumResponseTokens: maximumTokens),
        GenerationOptions(
            samplingMode: .random(probabilityThreshold: 0.9, seed: 1),
            maximumResponseTokens: maximumTokens
        )
    ]

    static let instructions = """
    家計簿アプリの振り返りで、次の期間の目標を決めた理由を、短く書く。読む人は、自分の家計を見直したい人である。
    渡された事実だけを使う。事実に無い数字・理由・品物・店・カテゴリは書かない。数字は事実に書かれたとおりに写す。
    事実の金額や回数を引き算・割り算しない。「〜円 増えました」「〜回 増えました」のような差は書かず、事実の数字をそのまま並べる。
    body には、締めた期間に何が増えたかを 1〜2 文で書く。回数や 1 回の金額の事実があれば、増えた理由として書く。
    目標そのものは別に出すので、目標の値や「〜してみましょう」を書かない。目標の額や割合を新しく作らない。
    丁寧語（です・ます）で書き、責めない。「〜すべき」「危ない」のような強い言い方をしない。
    投資・借入・保険・クレジットカードの申し込みなど、金融の商品は勧めない。ほかの家庭とは比べない。
    """

    static func respond(
        basis: String,
        scale: ReviewPeriod.Scale,
        options: GenerationOptions
    ) async -> String? {
        let name = scale.unitName

        let prompt = """
        この\(name)は終わった。
        期間は「\(name)」と呼ぶ。ほかの単位（週・月・年）で書かない。
        事実：
        \(basis)
        """

        let session = LanguageModelSession(
            model: .default,
            instructions: instructions
        )

        let attempt = try? await session.respond(
            to: prompt,
            generating: Comment.self,
            options: options
        )

        guard let response = attempt else {
            return nil
        }

        let cleaned = ReviewComment.cleaned(response.content.body)
        let body = ReviewComment.droppingAdvice(cleaned)

        return body.isEmpty ? nil : body
    }
}
