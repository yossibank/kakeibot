import DesignSystem
import SwiftUI

struct EntryMemoSheet: View {
    @Bindable var model: EntryModel

    @FocusState private var isFocused: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FittedSheet {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("メモ")
                        .font(.headline)
                        .foregroundStyle(Palette.champagne)

                    Spacer()

                    Button("完了") { dismiss() }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Palette.gold)
                        .frame(minWidth: 44, minHeight: 32)
                }

                TextField(
                    "メモ",
                    text: $model.memo,
                    prompt: Text("メモを書く").foregroundStyle(Palette.dusk),
                    axis: .vertical
                )
                .lineLimit(2...5)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .tint(Palette.gold)
                .focused($isFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Palette.gold.opacity(0.6), lineWidth: 1)
                }

                if !model.recentMemos.isEmpty {
                    Text("最近のメモ")
                        .font(.caption)
                        .foregroundStyle(Palette.mist)

                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(model.recentMemos, id: \.self) { memo in
                                suggestionButton(memo)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .task {
            isFocused = true
        }
    }
}

private extension EntryMemoSheet {
    func suggestionButton(_ memo: String) -> some View {
        Button(memo) {
            model.memo = memo
        }
        .font(.caption)
        .foregroundStyle(Palette.ink)
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
        .buttonStyle(.plain)
    }
}
