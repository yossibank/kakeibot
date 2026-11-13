import DesignSystem
import SwiftUI

struct EntryRecentRow<Content: View>: View {
    let title: String

    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("前と同じ内容で入れる")
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.subtext)

                Spacer()

                Text(title)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.hint)
            }
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
        let amountOpacity = amount == nil ? 0.0 : 1.0

        Button(action: onUse) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    mark

                    Text(title)
                        .textFont(.caption, weight: .bold)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                AmountText(amount ?? 0, font: .size(.headline, weight: .semibold))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .opacity(amountOpacity)
                    .overlay(alignment: .leading) {
                        if amount == nil {
                            Text("毎回入れる")
                                .textFont(.footnote, weight: .semibold)
                                .foregroundStyle(Palette.hint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .fixedSize()
                        }
                    }

                Text(detail)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 112, alignment: .leading)
            .background(Palette.cardTop, in: shape)
            .overlay {
                shape
                    .stroke(Palette.line, lineWidth: 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}
