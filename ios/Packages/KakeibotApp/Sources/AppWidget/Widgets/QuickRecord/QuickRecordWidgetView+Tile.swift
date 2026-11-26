import Core
import DesignSystem
import SwiftUI
import WidgetKit

extension QuickRecordWidgetView {
    static let tileRadius: CGFloat = 12
    static let recordIconSize: CGFloat = 24
    static let markSize: CGFloat = 20

    var iconSize: CGFloat {
        isLarge ? 30 : 26
    }

    @ViewBuilder
    func tileButton(
        _ tile: QuickRecordWidgetSummary.Tile,
        padding: CGFloat
    ) -> some View {
        if tile.amount != nil {
            Button(intent: QuickRecordIntent(tile.id)) {
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
        HStack(spacing: 8) {
            IconTile(tile.icon, size: iconSize)
                .foregroundStyle(Palette.accentStrong)

            ViewThatFits(in: .vertical) {
                tileText(tile, spacing: 4)
                tileText(tile, spacing: 1)
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
        .padding(.horizontal, 8)
        .padding(.vertical, padding / 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .templateCardFace(cornerRadius: Self.tileRadius, shadowRadius: 4)
    }

    func tileText(
        _ tile: QuickRecordWidgetSummary.Tile,
        spacing: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(tile.name)
                .textFont(size: .caption, weight: .medium)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if isLarge {
                ViewThatFits(in: .horizontal) {
                    detailText(tile.detail)
                    detailText(tile.shortDetail)
                }
            }

            if let amount = tile.amount {
                AmountText(
                    amount,
                    font: .size(.body, weight: .medium),
                    color: Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .privacySensitive()
            } else {
                Text("毎回入れる")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.hint)
            }
        }
    }

    func detailText(_ detail: String) -> some View {
        Text(detail)
            .textFont(size: .micro)
            .foregroundStyle(Palette.subtext)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
