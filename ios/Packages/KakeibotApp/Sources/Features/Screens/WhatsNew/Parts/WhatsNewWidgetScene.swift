import Core
import DesignSystem
import SwiftUI

struct WhatsNewWidgetScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .receipt:
            receipt

        case .tiles:
            widget
        }
    }
}

extension WhatsNewWidgetScene {
    enum Step: Hashable, Sendable {
        case tiles
        case receipt
    }
}

private extension WhatsNewWidgetScene {
    var widget: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("すぐ記録")
                .textFont(size: .micro)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                GridRow {
                    tile(Self.tiles[0])
                    tile(Self.tiles[1])
                }

                GridRow {
                    tile(Self.tiles[2])
                    tile(Self.tiles[3])
                }
            }
        }
        .padding(8)
        .card(cornerRadius: 16)
        .padding(.horizontal, 2)
    }

    var receipt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("すぐ記録")
                .textFont(size: .caption)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            Label("レシート", systemImage: "doc.text.viewfinder")
                .textFont(size: .caption, weight: .medium)
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay {
                    Capsule()
                        .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 1)
                }
                .whatsNewTapped()
        }
        .padding(12)
        .card(cornerRadius: 16)
    }

    func tile(_ tile: WidgetGuideStage.Tile) -> some View {
        HStack(spacing: 4) {
            IconTile(WidgetGuideStage.icon(tile.glyph, color: tile.color), size: 20)

            Text(tile.name)
                .textFont(size: .micro, weight: .medium)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 0)
        }
        .padding(4)
        .frame(height: 40)
        .templateCardFace(cornerRadius: 8, shadowRadius: 2)
    }
}

private extension WhatsNewWidgetScene {
    static let tiles = Array(WidgetGuideStage.tiles[1...4])
}
