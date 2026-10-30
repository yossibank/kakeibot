import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    var searchBar: some View {
        HStack(spacing: 12) {
            SearchField(
                "メモ・カテゴリ・タグ・口座・金額",
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
            if model.recentSearches.isEmpty {
                Text("メモ・カテゴリ・タグ・口座の名前や、金額で探せます")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 40)
            } else {
                recentList
            }
        } else if let summary = model.searchSummary {
            searchSummary(summary)

            ForEach(days, id: \.date) { day in
                dayCard(day)
            }
        } else if model.isSearchHiddenByFilter {
            filteredEmpty
        } else {
            Text("見つかりませんでした")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .padding(.vertical, 40)
        }
    }
}

private extension RecordsView {
    var recentList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionTitle("最近探した言葉")

                Spacer()

                Button {
                    Task {
                        await model.clearRecentSearches()
                    }
                } label: {
                    Text("消す")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 36)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            ForEach(model.recentSearches, id: \.self) { word in
                Button {
                    model.searchText = word
                    rememberSearch()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .sansFont(.small)
                            .foregroundStyle(Palette.subtext)

                        Text(word)
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.text)
                            .sharedTextScale()

                        Spacer()
                    }
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    Hairline(thickness: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
        .sharesTextScale(id: model.recentSearches)
    }
}

private extension RecordsView {
    func rememberSearch() {
        let text = model.searchText

        Task {
            await model.rememberSearch(text)
        }
    }

    func closeSearch() {
        isSearchFocused = false
        openId = nil

        if model.searchSummary != nil {
            rememberSearch()
        }

        withAnimation(.snappy) {
            model.closeSearch()
        }
    }
}
