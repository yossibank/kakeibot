import Core
import DesignSystem
import SwiftUI

struct CategoryTagCard: View {
    @Binding var name: String

    var isFocused: FocusState<Bool?>.Binding

    let isAdding: Bool
    let errorMessage: String?
    let onCommit: () -> Void
    let onDelete: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            header

            preview

            VStack(alignment: .leading, spacing: 8) {
                SettingsField(
                    "朝ごはん など",
                    text: $name,
                    isInvalid: errorMessage != nil,
                    focus: isFocused,
                    field: true,
                    onSubmit: onCommit
                )

                Text(note)
                    .textFont(.caption2)
                    .foregroundStyle(noteColor)
                    .padding(.leading, 4)
            }

            PrimaryButton(commitTitle, action: onCommit)
        }
        .padding(16)
        .floatingCard()
        .task {
            isFocused.wrappedValue = true
        }
    }
}

private extension CategoryTagCard {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark", action: onClose)

            Spacer()

            Label(title, systemImage: "tag")
                .textFont(.caption)
                .foregroundStyle(Palette.accent)

            Spacer()

            if let onDelete {
                RingButton(
                    systemImage: "trash",
                    style: .destructive,
                    label: "削除",
                    action: onDelete
                )
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }

    var preview: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.outline)
                .frame(width: 0.8, height: 14)

            TagCard(previewName, style: .selected)
                .scaleEffect(1.3, anchor: .top)
                .frame(height: 40, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            Rectangle()
                .fill(Palette.outline)
                .frame(width: 120, height: 0.8)
        }
        .animation(.snappy(duration: 0.2), value: name)
    }
}

private extension CategoryTagCard {
    var title: String {
        isAdding ? "タグを追加" : "タグを編集"
    }

    var commitTitle: String {
        isAdding ? "追加する" : "変更する"
    }

    var previewName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        return trimmed.isEmpty ? "名前" : trimmed
    }

    var note: String {
        errorMessage ?? "\(EntryTagDraft.maxNameLength) 文字まで"
    }

    var noteColor: Color {
        errorMessage == nil ? Palette.subtext : Palette.rose
    }
}
