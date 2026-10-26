import DesignSystem
import SwiftUI

struct EntryEditActions: View {
    let onAdd: (() -> Void)?
    let onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            if let onAdd {
                action("追加", systemImage: "plus", perform: onAdd)
            }

            if let onEdit {
                action("編集", systemImage: "gearshape", perform: onEdit)
            }
        }
    }
}

private extension EntryEditActions {
    func action(
        _ title: String,
        systemImage: String,
        perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .textFont(size: .caption)
                .foregroundStyle(Palette.accent)
                .frame(minHeight: 28)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
