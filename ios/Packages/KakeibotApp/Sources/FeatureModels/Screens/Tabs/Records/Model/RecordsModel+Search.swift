import Core
import Store

public extension RecordsModel {
    struct SearchSummary: Equatable {
        public let count: Int
        public let expenseTotal: Int
        public let incomeTotal: Int
        public let range: ClosedRange<LocalDate>
    }
}

public extension RecordsModel {
    func rememberSearch(_ text: String) async {
        let words = EntrySearch.remembering(text, in: input.recentSearches)

        guard words != input.recentSearches else {
            return
        }

        input.recentSearches = words
        await saveRecentSearches()
    }

    func clearRecentSearches() async {
        state.notices.clearedSearches.show(input.recentSearches)
        input.recentSearches = []
        await saveRecentSearches()
    }

    func restoreRecentSearches() async {
        guard let words = state.notices.clearedSearches.take() else {
            return
        }

        do {
            try await dependencies.database.setSetting(.recentSearches, to: words)
        } catch {
            state.notices.error.show(Self.saveFailedMessage, for: error)
        }
    }
}

private extension RecordsModel {
    func saveRecentSearches() async {
        do {
            try await dependencies.database.setSetting(.recentSearches, to: input.recentSearches)
        } catch {
            state.notices.error.show(Self.saveFailedMessage, for: error)
        }
    }
}
