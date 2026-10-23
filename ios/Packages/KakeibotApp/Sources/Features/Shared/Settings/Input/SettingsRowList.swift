import Core
import DesignSystem
import SwiftUI

struct SettingsRowList<Panel: Hashable>: View {
    @Environment(\.themeStyle.displayFont) private var themeFont
    @Environment(\.themeStyle.textFont) private var textFont
    @Environment(\.themeStyle.textSize.scale) private var textScale
    @Environment(\.themeStyle.corner) private var corner

    let items: [Item]
    let onOpen: (Panel) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                rowButton(item)
                    .overlay(alignment: .top) {
                        if index > 0 {
                            Hairline(thickness: 1)
                        }
                    }
            }
        }
        .background(Self.cardFill.opacity(0.7), in: shape)
        .overlay {
            shape
                .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
        }
    }
}

extension SettingsRowList {
    struct Item {
        let panel: Panel
        let systemImage: String
        let title: String
        let value: String
        let isEmpty: Bool
        let isAmount: Bool

        init(
            panel: Panel,
            systemImage: String,
            title: String,
            value: String,
            isEmpty: Bool,
            isAmount: Bool = false
        ) {
            self.panel = panel
            self.systemImage = systemImage
            self.title = title
            self.value = value
            self.isEmpty = isEmpty
            self.isAmount = isAmount
        }
    }
}

private extension SettingsRowList {
    func rowButton(_ item: Item) -> some View {
        let isAmount = item.isAmount && !item.isEmpty

        let amountFont = Font.display(
            .headline,
            in: themeFont,
            scale: textScale
        )

        let textFont = Font.text(.subheadline, in: textFont, scale: textScale)
        let font = isAmount ? amountFont : textFont
        let color = item.isEmpty ? Palette.hint : Palette.accentStrong

        return Button {
            onOpen(item.panel)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.systemImage)
                    .sansFont(.small)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 28, height: 28)
                    .background(Palette.accent.opacity(.subtle), in: Circle())

                Text(item.title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 12)

                Text(item.value)
                    .font(font)
                    .foregroundStyle(color)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Palette.accent.opacity(.medium))
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension SettingsRowList {
    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(20))
    }
}
