import DesignSystem
import SwiftUI

struct RecordsSearchHistory: View {
    let clearedWords: [String]?
    let words: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void
    let onRestore: () -> Void
    let onLeave: () -> Void

    var body: some View {
        Group {
            if words.isEmpty {
                guide
            } else {
                list
            }
        }
        .onDisappear {
            if clearedWords != nil {
                onLeave()
            }
        }
    }
}

private extension RecordsSearchHistory {
    var guide: some View {
        VStack(spacing: 8) {
            Text("メモ・カテゴリ・タグ・口座の名前や、金額で探せます")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            if clearedWords != nil {
                undoLine
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 40)
        .animation(.snappy, value: clearedWords)
    }

    var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("最近探した言葉") {
                Button {
                    onClear()
                } label: {
                    Text("履歴を消す")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 36)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            ForEach(words, id: \.self) { word in
                Button {
                    onSelect(word)
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
                .topHairline()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
        .sharesTextScale(id: words)
    }

    var undoLine: some View {
        HStack(spacing: 8) {
            Text("履歴を消しました")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Button {
                onRestore()
            } label: {
                Text("取り消す")
                    .textFont(.caption, weight: .bold)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 8)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    RecordsSearchHistory(
        clearedWords: nil,
        words: ["ランチ", "本", "¥500"],
        onSelect: { _ in },
        onClear: {},
        onRestore: {},
        onLeave: {}
    )
    .padding()
    .background(Palette.background)
}
