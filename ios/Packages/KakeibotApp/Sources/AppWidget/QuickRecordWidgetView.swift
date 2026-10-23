import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct QuickRecordWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.themeStyle.corner) private var corner

    let entry: QuickRecordWidgetEntry

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(PlannedNotification.Route.home.url)
            .widgetTheme(entry.look, style: entry.style)
    }
}

private extension QuickRecordWidgetView {
    @ViewBuilder
    var content: some View {
        if let summary = entry.summary {
            VStack(spacing: 8) {
                header(of: summary)
                    .frame(height: Self.headerHeight)

                if summary.tiles.isEmpty {
                    Text("金額を決めたテンプレートを作ると、ここから記録できます")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    grid(of: summary)
                }
            }
        } else {
            Text("アプリを開くと、ここに出ます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    func header(of summary: QuickRecordWidgetSummary) -> some View {
        if let recorded = summary.recorded(at: entry.date) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Palette.accent)

                Text("\(recorded.name) \(AmountText.text(recorded.amount)) を記録しました")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .privacySensitive()

                Spacer(minLength: 4)

                Button(intent: UndoWidgetEntryIntent(recorded.id)) {
                    Text("取り消す")
                        .textFont(size: .caption, weight: .semibold)
                        .foregroundStyle(Palette.accentStrong)
                        .padding(.horizontal, 12)
                        .frame(maxHeight: .infinity)
                        .overlay {
                            Capsule()
                                .strokeBorder(Palette.outline, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                Text("すぐ記録")
                    .textFont(size: .caption)
                    .tracking(1)
                    .foregroundStyle(Palette.accent)

                Spacer(minLength: 4)

                Text("今日 \(AmountText.text(summary.todayExpense))")
                    .textFont(size: .caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .privacySensitive()
            }
            .frame(maxHeight: .infinity)
        }
    }

    func grid(of summary: QuickRecordWidgetSummary) -> some View {
        let tiles = Array(summary.tiles.prefix(rowCount * Self.columns))

        return Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(0..<rowCount, id: \.self) { row in
                GridRow {
                    ForEach(0..<Self.columns, id: \.self) { column in
                        let index = row * Self.columns + column

                        if index < tiles.count {
                            tileButton(tiles[index])
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    func tileButton(_ tile: QuickRecordWidgetSummary.Tile) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(Self.tileRadius))

        return Button(intent: RecordTemplateIntent(tile.id)) {
            HStack(spacing: 8) {
                IconImage(tile.icon, size: 14)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Self.badgeSize, height: Self.badgeSize)
                    .background(Palette.faint, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(tile.name)
                        .textFont(size: .caption, weight: .medium)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)

                    Text(AmountText.text(tile.amount))
                        .displayFont(.body, weight: .medium)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .privacySensitive()
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.card, in: shape)
            .overlay {
                shape
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension QuickRecordWidgetView {
    static let columns = 2
    static let headerHeight: CGFloat = 24
    static let tileRadius: CGFloat = 14
    static let badgeSize: CGFloat = 28

    var rowCount: Int {
        family == .systemLarge ? 4 : 2
    }
}
