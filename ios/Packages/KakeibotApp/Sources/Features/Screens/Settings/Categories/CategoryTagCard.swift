import Core
import DesignSystem
import SwiftUI

struct CategoryTagCard: View {
    @Binding var name: String

    @Environment(\.themeStyle.corner) private var corner

    var isFocused: FocusState<Bool>.Binding

    let isAdding: Bool
    let errorMessage: String?
    let onCommit: () -> Void
    let onDelete: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label(title, systemImage: "tag")
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)

                Spacer()
                RingButton(systemImage: "xmark", action: onClose)
            }

            preview

            VStack(alignment: .leading, spacing: 6) {
                field

                Text(note)
                    .textFont(.caption2)
                    .foregroundStyle(noteColor)
                    .padding(.leading, 4)
            }

            HStack(spacing: 10) {
                if let onDelete {
                    Button(action: onDelete) {
                        Text("削除")
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.rose)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .overlay {
                                Capsule()
                                    .stroke(Palette.rose.opacity(.medium))
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onCommit) {
                    Text(commitTitle)
                        .textFont(.subheadline, weight: .bold)
                        .foregroundStyle(Palette.background)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Palette.accent, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
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

private extension CategoryTagCard {
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

    var field: some View {
        TextField(
            "名前",
            text: $name,
            prompt: Text("朝ごはん など").foregroundStyle(Palette.hint)
        )
        .textFont(.body)
        .foregroundStyle(Palette.text)
        .tint(Palette.accent)
        .submitLabel(.done)
        .focused(isFocused)
        .onSubmit(onCommit)
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(
            Palette.background,
            in: .rect(cornerRadius: corner.radius(14))
        )
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(14))
                .stroke(fieldStroke, lineWidth: 1)
        }
    }
}

private extension CategoryTagCard {
    var title: String {
        isAdding ? "タグを追加" : "タグを変更"
    }

    var commitTitle: String {
        isAdding ? "追加" : "変更"
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

    var fieldStroke: Color {
        errorMessage == nil ? Palette.outline : Palette.rose
    }
}
