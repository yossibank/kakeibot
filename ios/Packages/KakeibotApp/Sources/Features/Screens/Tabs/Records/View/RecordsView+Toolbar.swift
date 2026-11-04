import DesignSystem
import SwiftUI

extension RecordsView {
    var selectButton: some View {
        let isSelecting = selection != nil

        return toolButton(
            systemImage: isSelecting ? "checkmark" : "checkmark.circle",
            title: isSelecting ? "完了" : "選択",
            isOn: isSelecting
        ) {
            withAnimation(.snappy) {
                selection = isSelecting ? nil : []
            }
        }
    }

    func filterButton(title: String?) -> some View {
        toolButton(
            systemImage: "line.3.horizontal.decrease",
            title: title,
            isOn: !model.filter.isEmpty
        ) {
            isFiltering = true
        }
    }

    func toolButton(
        systemImage: String,
        title: String? = nil,
        isOn: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let fill = isOn ? Palette.accent.opacity(.subtle) : Color.clear
        let ring = isOn ? Palette.accent : Palette.line

        return Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .sansFont(.small, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 36, height: 36)
                    .background(fill, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(ring, lineWidth: 1)
                    }

                if let title {
                    Text(title)
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .fixedSize()
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

extension RecordsView {
    func finishSelecting() {
        withAnimation(.snappy) {
            selection = nil
        }
    }
}
