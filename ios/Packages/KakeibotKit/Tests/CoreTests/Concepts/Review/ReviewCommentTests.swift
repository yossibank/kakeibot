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
        let calendar = Calendar(identifier: .gregorian)
        let comment = Self.comment(createdAt: Self.now)
        let sameDay = Self.now.addingTimeInterval(3600)
        let nextDay = Self.now.addingTimeInterval(86400)

        let unchanged = comment.needsRewrite(
            basis: Self.basis,
            isCurrent: true,
            today: nextDay,
            calendar: calendar
        )

        let today = comment.needsRewrite(
            basis: "別の事実",
            isCurrent: true,
            today: sameDay,
            calendar: calendar
        )

        let tomorrow = comment.needsRewrite(
            basis: "別の事実",
            isCurrent: true,
            today: nextDay,
            calendar: calendar
        )

        let finished = comment.needsRewrite(
            basis: "別の事実",
            isCurrent: false,
            today: sameDay,
            calendar: calendar
        )

        #expect(!unchanged)
        #expect(!today)
        #expect(tomorrow)
        #expect(finished)
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
            suggestion: "残りの 12 日は 1 日 150円にすると収まります。",
            basis: basis,
            createdAt: createdAt
        )
    }
}
