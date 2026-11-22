import Core
import Foundation
import Testing

struct ReviewCommentTests {
    @Test
    func acceptsNumbersFromBasis() {
        let text = "食費が、予算の 97% に届いています。残りの 12 日は 1 日 150 円にすると収まります。"

        #expect(ReviewComment.isGrounded(text, in: Self.basis, categories: Self.categories))
    }

    @Test
    func rejectsInventedNumbers() {
        let text = "食費が 3 回多く、予算の 97% に届いています。"

        #expect(!ReviewComment.isGrounded(text, in: Self.basis, categories: Self.categories))
    }

    @Test
    func rejectsInventedCategories() {
        let text = "食費が、予算の 97% に届いています。交際費も控えめにしてみましょう。"

        #expect(!ReviewComment.isGrounded(text, in: Self.basis, categories: Self.categories))
    }

    @Test
    func readsGroupedAndFullWidthNumbers() {
        let basis = "収入の 265,000円 から、82,600円 残せました。"

        #expect(ReviewComment.isGrounded("８２，６００円を残せました。", in: basis, categories: []))
        #expect(!ReviewComment.isGrounded("82,000円を残せました。", in: basis, categories: []))
    }

    @Test
    func keepsOnlyGroundedSentences() {
        let basis = "気を付けたい点：住まいの 1 回の出費 78,000円 が、支出の 42% を占めています。\n良い点：収入の 280,000円 から、95,540円 残せました。"
        let text = "収入の 280,000 円から 95,540 円が残りました。住まいの 1 回の出費 78,000 円が支出の 42% を占めています。住まいの出費は前月より 18,000 円増えました。"
        let invented = "住まいの出費は前月より 18,000 円増えました。"

        let kept = ReviewComment.grounded(text, in: basis, categories: ["住まい"])
        let empty = ReviewComment.grounded(invented, in: basis, categories: ["住まい"])

        #expect(kept == "収入の 280,000 円から 95,540 円が残りました。住まいの 1 回の出費 78,000 円が支出の 42% を占めています。")
        #expect(empty.isEmpty)
    }

    @Test
    func cutsBrokenTail() {
        let broken = "次の期間に支出のペースを確認してみましょう。」} }  ```  ```  ```json  {"
        let quoted = "「残りの日は控えめにすると収まります。」"

        #expect(ReviewComment.cleaned(broken) == "次の期間に支出のペースを確認してみましょう。")
        #expect(ReviewComment.cleaned(quoted) == "残りの日は控えめにすると収まります。")
    }

    @Test
    func dropsAdviceSentences() {
        let text = "82,600円 残せたのは良い点です。支出のペースを見直してみましょう。"
        let request = "交際費が増えています。記録を確かめてみてください。"
        let advice = "支出を見直してみましょう。"

        #expect(ReviewComment.droppingAdvice(text) == "82,600円 残せたのは良い点です。")
        #expect(ReviewComment.droppingAdvice(request) == "交際費が増えています。")
        #expect(ReviewComment.droppingAdvice(advice).isEmpty)
    }

    @Test
    func rewritesWhenBasisChanges() {
        let comment = Self.comment(createdAt: Self.now)

        #expect(!comment.needsRewrite(basis: Self.basis))
        #expect(comment.needsRewrite(basis: "別の事実"))
    }

    @Test
    func keysPeriodByScaleAndStart() throws {
        let date = try #require(LocalDate("2026-11-18"))

        let period = ReviewPeriod(
            scale: .month,
            containing: date,
            monthStartDay: .first,
            weekStart: .sunday
        )

        #expect(period.commentKey == "month:2026-11-01")
    }
}

private extension ReviewCommentTests {
    static let basis = "食費は、期間の 60% が過ぎたところで、予算の 97% を使っています。予算に収めるには、残りの 12 日を 1 日 150円 にします。"
    static let categories = ["食費", "交際費", "交通"]
    static let now = Date(timeIntervalSince1970: 1_794_000_000)

    static func comment(createdAt: Date) -> ReviewComment {
        ReviewComment(
            period: "month:2026-11-01",
            body: "食費が、予算の 97% に届いています。",
            basis: basis,
            createdAt: createdAt
        )
    }
}
