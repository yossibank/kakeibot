import Core
import Testing

struct EntrySearchTests {
    @Test(arguments: try cases)
    func matchesWords(fixture: SearchCase) {
        let search = EntrySearch(fixture.query)

        let matches = search.matches(
            amount: fixture.amount,
            texts: fixture.texts
        )

        #expect(matches == fixture.matches)
    }

    @Test
    func splitsOnAnySpace() {
        let search = EntrySearch("  ランチ　財布 ")

        #expect(search.words == ["ランチ", "財布"])
        #expect(EntrySearch(" ").isEmpty)
    }
}

extension EntrySearchTests {
    struct SearchCase: Decodable, Sendable {
        let query: String
        let amount: Int
        let texts: [String]
        let matches: Bool
    }
}

private extension EntrySearchTests {
    static var cases: [SearchCase] {
        get throws {
            try Fixture.load("entry/entry-search.json")
        }
    }
}
