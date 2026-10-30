import Core
import DesignSystem
import SwiftUI

struct EntryMemoCard: View {
    @Bindable var model: EntryModel

    let isFocused: FocusState<Bool>.Binding
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("メモ", systemImage: "square.and.pencil")
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)

                Spacer()

                RingButton(
                    systemImage: "checkmark",
                    style: .prominent,
                    action: onDone
                )
            }

            TextField(
                "メモ",
                text: $model.memo,
                prompt: Text(model.memoPrompt).foregroundStyle(Palette.hint),
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFont(.subheadline)
            .foregroundStyle(Palette.text)
            .tint(Palette.accent)
            .focused(isFocused)

            if !model.recentMemos.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(model.recentMemos, id: \.self) { memo in
                            suggestionButton(memo)
                        }
                    }
                    .sharesTextScale(id: model.recentMemos)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(16)
        .floatingCard()
        .task {
            isFocused.wrappedValue = true
        }
    }
}

private extension EntryMemoCard {
    func suggestionButton(_ memo: String) -> some View {
        ChipButton {
            model.memo = memo
        } content: {
            Text(memo)
                .sharedTextScale()
        }
    }
}
