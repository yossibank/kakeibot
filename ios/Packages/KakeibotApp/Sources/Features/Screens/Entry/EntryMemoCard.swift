import Core
import DesignSystem
import SwiftUI

struct EntryMemoCard: View {
    @Bindable var model: EntryModel

    @Environment(\.themeStyle.corner) private var corner

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
        .background(Palette.panel, in: .rect(cornerRadius: corner.radius(20)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(20))
                .stroke(Palette.outline, lineWidth: 1)
        }
        .shadow(color: Palette.shadow.opacity(0.45), radius: 20, y: 10)
        .task {
            isFocused.wrappedValue = true
        }
    }
}

private extension EntryMemoCard {
    func suggestionButton(_ memo: String) -> some View {
        Button {
            model.memo = memo
        } label: {
            Text(memo)
                .textFont(.caption)
                .foregroundStyle(Palette.text)
                .sharedTextScale()
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
