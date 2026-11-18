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
        isCurrent: Bool,
        onReject: (String) -> Void = { _ in }
    ) async -> String? {
        guard isUsable else {
            return nil
        }

        for options in attempts {
            let attempt = await respond(
                basis: basis,
                scale: scale,
                isCurrent: isCurrent,
                options: options
            )

            guard let body = attempt else {
                onReject("答えが返らなかった")
                continue
            }

            let isGrounded = ReviewComment.isGrounded(
                body,
                in: basis,
                categories: categories
            )

            guard isGrounded else {
                onReject(body)
                continue
            }

            return body
        }

        return nil
    }
}

@available(iOS 26.0, *)
private extension ReviewCommentModel {
    @Generable
    struct Comment {
        @Guide(description: "事実から分かる気づき。1〜3 文の丁寧語")
        var body: String
    }

    static let locale = Locale(identifier: "ja_JP")
    static let maximumTokens = 200

    static let attempts = [
        GenerationOptions(sampling: .greedy, maximumResponseTokens: maximumTokens),
        GenerationOptions(
            sampling: .random(probabilityThreshold: 0.9, seed: 1),
            maximumResponseTokens: maximumTokens
        )
    ]

    static let instructions = """
    家計簿アプリの振り返りの画面に出す、短いひとことを書く。読む人は、自分の家計を見直したい人である。
    渡された事実だけを使う。事実に無い数字・理由・品物・店・カテゴリは書かない。数字は事実に書かれたとおりに写す。
    body には、事実から分かる気づきを 1〜3 文で書く。グラフを見れば分かる合計の言い直しより、ペースや増え方を書く。
    文の数は、事実の行の数までにする。回数や 1 回の額の事実があれば、増えた理由として書く。
    見直しの提案は別に出すので、body には提案や「〜してみましょう」を書かない。
    目標の額や割合を新しく作らない。事実に無い割合を計算しない。
    事実の頭の「良い点」「気を付けたい点」「事実」の印は、文に写さない。
    丁寧語（です・ます）で書き、責めない。「〜すべき」「危ない」のような強い言い方をしない。
    事実の頭の「良い点」は認め、「気を付けたい点」は良いこととして書かない。「事実」は良い悪いを決めずに書く。
    投資・借入・保険・クレジットカードの申し込みなど、金融の商品は勧めない。ほかの家庭とは比べない。
    """

    static func respond(
        basis: String,
        scale: ReviewPeriod.Scale,
        isCurrent: Bool,
        options: GenerationOptions
    ) async -> String? {
        let name = scale.unitName

        let timing = isCurrent
            ? "この\(name)はまだ途中である。"
            : "この\(name)は終わった。"

        let prompt = """
        \(timing)
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
