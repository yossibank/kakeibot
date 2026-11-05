import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    var searchBar: some View {
        HStack(spacing: 12) {
            SearchField(
                "メモや金額で探す",
                text: $model.searchText,
                focus: $isSearchFocused
            ) {
                rememberSearch()
            }

            filterButton(title: nil)

            Button {
                closeSearch()
            } label: {
                Text("閉じる")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    var searchContent: some View {
        let days = model.searchDays

        if EntrySearch(model.searchText).isEmpty {
            RecordsSearchHistory(
                words: model.recentSearches,
                onSelect: selectRecent,
                onClear: clearRecent,
                onRestore: restoreRecent
            )
        } else if let summary = model.searchSummary {
            searchSummary(summary)

            ForEach(days, id: \.date) { day in
                dayCard(day)
            }
        } else {
            searchEmpty
        }
    }
}

private extension RecordsView {
    var searchEmpty: some View {
        let word = model.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hiddenCount = model.searchHiddenCount

        return PlaceholderEmpty(
            systemImage: "magnifyingglass",
            text: "「\(word)」は見つかりませんでした",
            detail: "金額やメモの一部でも探せます"
        ) {
            if hiddenCount > 0 {
                RecordsFilterClearButton(count: hiddenCount) {
                    clearFilter()
                }
            }
        }
    }
}

private extension RecordsView {
    func rememberSearch() {
        let text = model.searchText

        Task {
            await model.rememberSearch(text)
        }
    }

    func selectRecent(_ word: String) {
        model.searchText = word
        rememberSearch()
    }

    func clearRecent() {
        Task {
            await model.clearRecentSearches()
        }
    }

    func restoreRecent(_ words: [String]) {
        Task {
            await model.restoreRecentSearches(words)
        }
    }

    func closeSearch() {
        isSearchFocused = false

        if model.searchSummary != nil {
            rememberSearch()
        }

        withAnimation(.snappy) {
            model.closeSearch()
        }
    }
}
