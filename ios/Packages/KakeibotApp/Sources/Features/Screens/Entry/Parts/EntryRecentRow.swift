import Core
import DesignSystem
import SwiftUI

struct EntryRecentRow<Content: View>: View {
    let title: String
    let rows: Int

    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(Palette.subtext)
                .padding(.horizontal, 4)

            ScrollView(.horizontal) {
                LazyHGrid(rows: gridRows, spacing: 8) {
                    content
                }
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension EntryRecentRow {
    var gridRows: [GridItem] {
        let row = GridItem(
            .fixed(EntryRecentCard<EmptyView>.height),
            spacing: 8,
            alignment: .leading
        )

        return Array(repeating: row, count: rows)
    }
}

struct EntryRecentCard<Mark: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    let title: String
    let amount: Int?
    let detail: String
    let isPinned: Bool
    let onUse: () -> Void

    @ViewBuilder let mark: Mark

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        Button(action: onUse) {
            CappedWidthLayout(maxWidth: Self.maxWidth) {
                HStack(spacing: 8) {
                    mark

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            if isPinned {
                                Image(systemName: "pin.fill")
                                    .sansFont(.micro, weight: .bold)
                                    .foregroundStyle(Palette.accent)
                            }

                            Text(title)
                                .textFont(.caption, weight: .bold)
                                .foregroundStyle(Palette.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

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
                .frame(height: Self.height, alignment: .leading)
            }
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

extension EntryRecentCard {
    static var height: CGFloat {
        48
    }
}

private extension EntryRecentCard {
    static var maxWidth: CGFloat {
        240
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

private struct CappedWidthLayout: Layout {
    let maxWidth: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }

        let ideal = subview.sizeThatFits(.unspecified)
        let width = min(ideal.width, maxWidth)
        return subview.sizeThatFits(ProposedViewSize(width: width, height: proposal.height))
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}
