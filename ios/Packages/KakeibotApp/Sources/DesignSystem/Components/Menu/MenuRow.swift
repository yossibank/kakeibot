import SwiftUI

public struct MenuRow: View {
    let title: String
    let note: String?
    let systemImage: String
    let isSelected: Bool
    let isDestructive: Bool
    let action: () -> Void

    public init(
        _ title: String,
        note: String? = nil,
        systemImage: String,
        isSelected: Bool = false,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.note = note
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.isDestructive = isDestructive
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(iconColor)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textFont(.subheadline)
                        .foregroundStyle(titleColor)

                    if let note {
                        Text(note)
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                    }
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .sansFont(.small, weight: .semibold)
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
    var iconColor: Color {
        isDestructive ? Palette.rose : Palette.accent
    }

    var titleColor: Color {
        switch (isDestructive, isSelected) {
        case (true, _): Palette.rose
        case (false, true): Palette.accentStrong
        case (false, false): Palette.text
        }
    }

    var selectionFill: Color {
        isSelected ? Palette.accent.opacity(.faint) : Color.clear
    }
}
