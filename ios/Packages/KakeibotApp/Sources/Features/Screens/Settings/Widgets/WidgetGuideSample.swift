import Core
import DesignSystem
import SwiftUI

struct WidgetGuideSample: View {
    let kind: Kind

    var body: some View {
        switch kind {
        case .budget: budget
        case .quickRecord: quickRecord
        case .lockScreen: lockScreen
        case .control: control
        }
    }
}

extension WidgetGuideSample {
    enum Kind {
        case budget
        case quickRecord
        case lockScreen
        case control
    }
}

private extension WidgetGuideSample {
    struct Tile: Hashable {
        let systemImage: String
        let name: String
        let amount: Int?
    }

    static let tiles = [
        Tile(systemImage: "cup.and.saucer", name: "コーヒー", amount: 450),
        Tile(systemImage: "fork.knife", name: "お昼", amount: 800),
        Tile(systemImage: "tram", name: "電車", amount: 220),
        Tile(systemImage: "cart", name: "買い物", amount: nil)
    ]

    static let homeSize: CGFloat = 148
    static let homeRadius: CGFloat = 22
    static let tileRadius: CGFloat = 12
    static let markSize: CGFloat = 18
}

private extension WidgetGuideSample {
    var wallpaper: LinearGradient {
        LinearGradient(
            colors: [Palette.accentDeep, Palette.accentStrong],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var budget: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("今月あといくら")
                    .textFont(size: .caption)
                    .tracking(1)
                    .foregroundStyle(Palette.accent)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 4)

                Text("あと 12 日")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
            }
            .lineLimit(1)

            Spacer(minLength: 4)

            ZStack(alignment: .bottom) {
                HalfDial(progress: 0.62)

                Text(AmountText.text(42180))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 20)
            }

            Spacer(minLength: 4)

            HStack(alignment: .firstTextBaseline) {
                Text("今日の支出")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 4)

                Text(AmountText.text(1200))
                    .textFont(size: .small, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.text)
            }
            .lineLimit(1)
        }
        .padding(14)
        .frame(width: Self.homeSize, height: Self.homeSize)
        .card(cornerRadius: Self.homeRadius)
    }

    var quickRecord: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("すぐ記録")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.accent)

                Spacer(minLength: 4)

                Text("今日の支出 \(AmountText.text(1200))")
                    .textFont(size: .caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }
            .lineLimit(1)

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
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
        .padding(14)
        .frame(height: Self.homeSize)
        .frame(maxWidth: .infinity)
        .card(cornerRadius: Self.homeRadius)
    }

    var lockScreen: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: 0.62)
                    .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("あと")
                        .textFont(size: .micro)

                    Text("4.2万")
                        .displayFont(.small, weight: .bold)
                        .monospacedDigit()
                }
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("今月あといくら")
                        .textFont(.caption)

                    Spacer(minLength: 4)

                    Text("あと 12 日")
                        .textFont(.caption2)
                        .opacity(0.7)
                }

                Text(AmountText.text(42180))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()

                Text("今日の支出 \(AmountText.text(1200))")
                    .textFont(.caption)
                    .monospacedDigit()
                    .opacity(0.7)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(wallpaper, in: .rect(cornerRadius: Self.homeRadius))
    }

    var control: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .sansFont(.headline, weight: .regular)
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.18), in: Circle())

            Text("記録する")
                .textFont(.subheadline, weight: .semibold)
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(wallpaper, in: .rect(cornerRadius: Self.homeRadius))
    }

    func tile(_ tile: Tile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: tile.systemImage)
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 20, height: 20)
                    .background(Palette.faint, in: Circle())

                Text(tile.name)
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            HStack(spacing: 4) {
                if let amount = tile.amount {
                    Text(AmountText.text(amount))
                        .displayFont(.body, weight: .medium)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
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
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Palette.backgroundTop)
                        .frame(width: Self.markSize, height: Self.markSize)
                        .background(Palette.accent, in: Circle())
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .templateCardFace(cornerRadius: Self.tileRadius, shadowRadius: 3)
    }
}
