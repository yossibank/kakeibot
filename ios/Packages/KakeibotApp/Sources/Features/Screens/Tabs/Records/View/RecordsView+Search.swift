import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension RecordsView {
    var searchBar: some View {
        HStack(spacing: 12) {
            SearchField(
                "メモや金額で探す",
                text: Bindable(model.state).fields.searchText,
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
        let days = model.output.searchDays

        if EntrySearch(model.state.fields.searchText).isEmpty {
            RecordsSearchHistory(
                clearedWords: Bindable(model.state).fields.clearedSearches,
                words: model.input.recentSearches,
                onSelect: selectRecent,
                onClear: clearRecent,
                onRestore: restoreRecent
            )
        } else if let summary = model.output.searchSummary {
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
        let word = model.state.fields.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hiddenCount = model.output.searchHiddenCount

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
        let text = model.state.fields.searchText

        model.perform {
            await $0.rememberSearch(text)
        }
    }

    func selectRecent(_ word: String) {
        model.state.fields.searchText = word
        rememberSearch()
    }

    func clearRecent() {
        model.perform {
            await $0.clearRecentSearches()
        }
    }

    func restoreRecent(_ words: [String]) {
        model.perform {
            await $0.restoreRecentSearches(words)
        }
    }

    func closeSearch() {
        isSearchFocused = false

        if model.output.searchSummary != nil {
            rememberSearch()
        }

        withAnimation(.snappy) {
            model.state.closeSearch()
        }
    }
}
