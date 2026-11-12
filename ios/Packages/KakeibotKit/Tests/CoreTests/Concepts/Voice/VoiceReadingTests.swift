import Core
import Foundation
import Testing

struct VoiceReadingTests {
    @Test
    func readsEveryField() {
        let reading = read("昨日、駅前でランチ980円、カードで")

        #expect(reading.amount == 980)
        #expect(reading.date == LocalDate(year: 2026, month: 11, day: 11))
        #expect(reading.walletId == Self.card.id)
        #expect(reading.categoryId == nil)
        #expect(reading.memo == "駅前でランチ")
        #expect(reading.count == 4)
    }

    @Test(arguments: [
        ("コンビニで1,280円", 1280),
        ("三千円", 3000),
        ("1万2000円", 12000),
        ("二万円", 20000),
        ("千五百円", 1500),
        ("ランチ 980", 980),
        ("980円を3日に", 980)
    ])
    func readsAmounts(text: String, amount: Int) {
        #expect(read(text).amount == amount)
    }

    @Test(arguments: [
        ("今日のランチ", "2026-11-12"),
        ("おととい", "2026-11-10"),
        ("一昨日", "2026-11-10"),
        ("11月3日に", "2026-11-03"),
        ("12月24日", "2025-12-24"),
        ("3日に", "2026-11-03"),
        ("15日に", "2026-10-15")
    ])
    func readsDates(text: String, date: String) {
        #expect(read(text).date == LocalDate(date))
    }

    @Test
    func keepsDateNumbersOutOfTheAmount() {
        let reading = read("3日 500円")

        #expect(reading.date == LocalDate(year: 2026, month: 11, day: 3))
        #expect(reading.amount == 500)
    }

    @Test
    func leavesAmountEmptyWhenOnlyADateIsSaid() {
        let reading = read("3日にコンビニ")

        #expect(reading.amount == nil)
        #expect(reading.memo == "コンビニ")
    }

    @Test
    func matchesNamesAcrossKana() {
        let reading = read("かーどで交通費 220円")

        #expect(reading.walletId == Self.card.id)
        #expect(reading.categoryId == Self.transport.id)
        #expect(reading.memo == "交通費")
    }

    @Test
    func prefersTheLongestName() {
        let reading = read("楽天カードで300円")

        #expect(reading.walletId == Self.rakuten.id)
    }

    @Test
    func usesTheModelChoiceOverNames() {
        let choice = VoiceReading.Choice(categoryIndex: 0, walletIndex: 2)
        let reading = read("交通費 カード 220円", choice: choice)

        #expect(reading.categoryId == Self.food.id)
        #expect(reading.walletId == Self.rakuten.id)
    }

    @Test
    func fallsBackToNamesWhenTheChoiceIsOutOfRange() {
        let choice = VoiceReading.Choice(categoryIndex: 9, walletIndex: nil)
        let reading = read("交通 220円", choice: choice)

        #expect(reading.categoryId == Self.transport.id)
    }

    @Test
    func readsNothingFromFillers() {
        let reading = read("えっと、あの")

        #expect(reading.isEmpty)
    }

    @Test
    func dropsSpokenEndingsFromTheMemo() {
        let reading = read("本屋で1200円払った")

        #expect(reading.memo == "本屋")
    }
}

private extension VoiceReadingTests {
    static let now = Date(timeIntervalSince1970: 1_790_000_000)
    static let today = LocalDate(year: 2026, month: 11, day: 12)!

    static let food = category("食費")
    static let transport = category("交通")
    static let cash = wallet("財布")
    static let card = wallet("カード")
    static let rakuten = wallet("楽天カード")

    static func category(_ name: String) -> EntryCategory {
        EntryCategory(
            kind: .expense,
            name: name,
            iconId: Icon.ID(),
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )
    }

    static func wallet(_ name: String) -> Wallet {
        Wallet(
            name: name,
            kind: .cash,
            iconId: Icon.ID(),
            initialBalance: 0,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )
    }

    func read(
        _ text: String,
        choice: VoiceReading.Choice? = nil
    ) -> VoiceReading {
        VoiceReading(
            text: text,
            today: Self.today,
            categories: [Self.food, Self.transport],
            wallets: [Self.cash, Self.card, Self.rakuten],
            choice: choice
        )
    }
}
