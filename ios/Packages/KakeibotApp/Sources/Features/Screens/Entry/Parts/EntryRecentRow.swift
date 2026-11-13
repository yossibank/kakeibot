import Core
import DesignSystem
import SwiftUI

struct EntryRecentRow<Content: View>: View {
    let title: String

    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(Palette.subtext)
                .padding(.horizontal, 4)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    content
                }
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }
}

struct EntryRecentCard<Mark: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    let title: String
    let amount: Int?
    let detail: String
    let onUse: () -> Void

    @ViewBuilder let mark: Mark

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        Button(action: onUse) {
            HStack(spacing: 8) {
                mark

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textFont(.caption, weight: .bold)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(detail)
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Spacer(minLength: 0)

                        amountLabel
                    }
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .frame(width: Self.width, height: Self.height, alignment: .leading)
            .background(Palette.card, in: shape)
            .overlay {
                shape
                    .strokeBorder(Palette.accent.opacity(.soft), lineWidth: 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

private extension EntryRecentCard {
    static var width: CGFloat {
        200
    }

    static var height: CGFloat {
        48
    }

    @ViewBuilder
    var amountLabel: some View {
        if let amount {
            AmountText(amount, font: .style(.footnote))
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .layoutPriority(1)
        } else {
            Text("毎回入れる")
                .textFont(.caption2, weight: .semibold)
                .foregroundStyle(Palette.hint)
                .fixedSize()
        }
    }
}

struct EntryRecentMark: View {
    @Environment(\.themeStyle.corner) private var corner

    let icon: Icon?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(8))
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.accent

        IconImage(icon, size: 14)
            .frame(width: Self.size, height: Self.size)
            .background(color.opacity(.subtle), in: shape)
            .overlay {
                shape
                    .strokeBorder(color.opacity(.medium), lineWidth: 1)
            }
    }
}

private extension EntryRecentMark {
    static let size: CGFloat = 32
}
