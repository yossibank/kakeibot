import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct EntryMemoCard: View {
    let model: EntryModel
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
                text: Bindable(model.state).fields.memo,
                prompt: Text(model.output.memoPrompt).foregroundStyle(Palette.hint),
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFont(.subheadline)
            .foregroundStyle(Palette.text)
            .tint(Palette.accent)
            .focused(isFocused)

            if !model.output.memoSuggestions.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(model.output.memoSuggestions, id: \.self) { memo in
                            suggestionButton(memo)
                        }
                    }
                    .sharesTextScale(id: model.output.memoSuggestions)
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
            model.state.fields.memo = memo
            onDone()
        } content: {
            Text(memo)
                .sharedTextScale()
        }
    }
}
