import Core
import DesignSystem
import SwiftUI
import WidgetKit

extension QuickRecordWidgetView {
    @ViewBuilder
    func tileButton(
        _ tile: QuickRecordWidgetSummary.Tile,
        padding: CGFloat
    ) -> some View {
        if tile.amount != nil {
            Button(intent: RecordTemplateIntent(tile.id)) {
                tileFace(tile, padding: padding)
            }
            .buttonStyle(.plain)
        } else if let url = PlannedNotification.Route.template(tile.id).url {
            Link(destination: url) {
                tileFace(tile, padding: padding)
            }
        } else {
            tileFace(tile, padding: padding)
        }
    }
}

private extension QuickRecordWidgetView {
    func tileFace(
        _ tile: QuickRecordWidgetSummary.Tile,
        padding: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                TemplateBadge(icon: tile.icon, size: .small)

                Text(tile.name)
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if isLarge {
                Text(tile.detail)
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.leading, Self.badgeSize + 4)
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                if let amount = tile.amount {
                    Text(AmountText.text(amount))
                        .displayFont(.body, weight: .medium)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .privacySensitive()
                } else {
                    Text("毎回入れる")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.hint)
                }

                Spacer(minLength: 0)

                if tile.amount == nil {
                    EditBadge(size: Self.markSize)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.backgroundTop)
                        .frame(width: Self.markSize, height: Self.markSize)
                        .background(Palette.accent, in: Circle())
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .templateCardFace(cornerRadius: Self.tileRadius, shadowRadius: 4)
    }
}

private extension QuickRecordWidgetView {
    static let tileRadius: CGFloat = 12
    static let markSize: CGFloat = 20
}
