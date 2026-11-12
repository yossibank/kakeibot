import Core
import Foundation
import Testing

struct VoiceReadingFixtureTests {
    @Test(arguments: try fixture.cases)
    func readsSpokenText(_ spoken: SpokenCase) throws {
        let fixture = try Self.fixture
        let today = try #require(LocalDate(fixture.today))
        let categories = fixture.categories.map(Self.category)
        let wallets = fixture.wallets.map(Self.wallet)

        let reading = VoiceReading(
            text: spoken.text,
            today: today,
            categories: categories,
            wallets: wallets
        )

        let category = categories.first { $0.id == reading.categoryId }?.name
        let wallet = wallets.first { $0.id == reading.walletId }?.name

        #expect(reading.amount == spoken.amount)
        #expect(reading.date == spoken.date.flatMap(LocalDate.init))
        #expect(category == spoken.category)
        #expect(wallet == spoken.wallet)
        #expect(reading.memo == spoken.memo)
    }
}

extension VoiceReadingFixtureTests {
    struct Fixture: Decodable, Sendable {
        let today: String
        let categories: [String]
        let wallets: [String]
        let cases: [SpokenCase]
    }

    struct SpokenCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let text: String
        let amount: Int?
        let date: String?
        let category: String?
        let wallet: String?
        let memo: String?

        var testDescription: String {
            summary
        }
    }

    static var fixture: Fixture {
        get throws {
            try CoreFixture.load("voice/voice-reading.json")
        }
    }
}

private extension VoiceReadingFixtureTests {
    static let now = Date(timeIntervalSince1970: 1_790_000_000)

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
}
