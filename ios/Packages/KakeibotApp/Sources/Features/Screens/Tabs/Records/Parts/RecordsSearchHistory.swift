import DesignSystem
import SwiftUI

struct RecordsSearchHistory: View {
    @State private var clearedWords: [String]?

    let words: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void
    let onRestore: ([String]) -> Void

    var body: some View {
        Group {
            if words.isEmpty {
                guide
            } else {
                list
            }
        }
        .task(id: clearedWords) {
            guard clearedWords != nil else {
                return
            }

            try? await Task.sleep(for: .seconds(Self.undoSeconds))

            guard !Task.isCancelled else {
                return
            }

            withAnimation(.snappy) {
                clearedWords = nil
            }
        }
    }
}

private extension RecordsSearchHistory {
    static let undoSeconds = 5
}

private extension RecordsSearchHistory {
    var guide: some View {
        VStack(spacing: 8) {
            Text("メモ・カテゴリ・タグ・口座の名前や、金額で探せます")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            if let clearedWords {
                undoLine(clearedWords)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 40)
    }

    var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("最近探した言葉") {
                Button {
                    clear()
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
                .overlay(alignment: .top) {
                    Hairline(thickness: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
        .sharesTextScale(id: words)
    }

    func undoLine(_ cleared: [String]) -> some View {
        HStack(spacing: 8) {
            Text("履歴を消しました")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Button {
                restore(cleared)
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

private extension RecordsSearchHistory {
    func clear() {
        withAnimation(.snappy) {
            clearedWords = words
        }

        onClear()
    }

    func restore(_ cleared: [String]) {
        withAnimation(.snappy) {
            clearedWords = nil
        }

        onRestore(cleared)
    }
}

#Preview {
    RecordsSearchHistory(
        words: ["ランチ", "本", "¥500"],
        onSelect: { _ in },
        onClear: {},
        onRestore: { _ in }
    )
    .padding()
    .background(Palette.background)
}
