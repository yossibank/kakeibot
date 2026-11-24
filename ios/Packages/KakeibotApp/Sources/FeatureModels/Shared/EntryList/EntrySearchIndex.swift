import Core
import Store

struct EntrySearchIndex {
    private let list: EntryList
    private let texts: [Entry.ID: [String]]

    init(_ list: EntryList) {
        let pairs = list.days
            .flatMap(\.entries)
            .map { ($0.id, list.searchTexts(of: $0).map(EntrySearch.fold)) }

        self.list = list

        self.texts = Dictionary(pairs) { first, _ in
            first
        }
    }
}

extension EntrySearchIndex {
    func days(matching search: EntrySearch) -> [EntryDay] {
        list.days.filtered { entry in
            search.matches(amount: entry.amount, folded: texts[entry.id] ?? [])
        }
    }
}
