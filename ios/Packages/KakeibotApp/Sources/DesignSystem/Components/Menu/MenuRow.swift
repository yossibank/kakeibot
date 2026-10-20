import SwiftUI

public struct MenuRow: View {
    let title: String
    let note: String?
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    public init(
        _ title: String,
        note: String? = nil,
        systemImage: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.note = note
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.sans(.body, weight: .light))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(titleColor)

                    if let note {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(Palette.subtext)
                    }
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.sans(.small, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(selectionFill)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension MenuRow {
    var titleColor: Color {
        isSelected ? Palette.accentStrong : Palette.text
    }

    var selectionFill: Color {
        isSelected ? Palette.accent.opacity(.faint) : Color.clear
    }
}
