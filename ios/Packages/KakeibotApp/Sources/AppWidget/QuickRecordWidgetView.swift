import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct QuickRecordWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: QuickRecordWidgetEntry

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(PlannedNotification.Route.home.url)
            .widgetTheme(entry.look, style: entry.style)
    }
}

private extension QuickRecordWidgetView {
    @ViewBuilder
    var content: some View {
        if let summary = entry.summary {
            VStack(spacing: 6) {
                header(of: summary)
                    .frame(height: Self.headerHeight)

                if summary.tiles.isEmpty {
                    Text("テンプレートを作ると、ここから記録できます")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    grid(of: summary)
                }

                if isLarge {
                    Rectangle()
                        .fill(Palette.line)
                        .frame(height: 1)

                    todayRecords(of: summary)
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

    @ViewBuilder
    func tileButton(_ tile: QuickRecordWidgetSummary.Tile) -> some View {
        if tile.amount != nil {
            Button(intent: RecordTemplateIntent(tile.id)) {
                tileFace(tile)
            }
            .buttonStyle(.plain)
        } else if let url = PlannedNotification.Route.template(tile.id).url {
            Link(destination: url) {
                tileFace(tile)
            }
        } else {
            tileFace(tile)
        }
    }

    func tileFace(_ tile: QuickRecordWidgetSummary.Tile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                IconImage(tile.icon, size: 11)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Self.badgeSize, height: Self.badgeSize)
                    .background(Palette.faint, in: Circle())

                Text(tile.name)
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .layoutPriority(1)

                if isLarge {
                    Text(tile.detail)
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 2)

            HStack(spacing: 4) {
                if let amount = tile.amount {
                    Text(AmountText.text(amount))
                        .displayFont(.body, weight: .medium)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .privacySensitive()
                } else {
                    Text("毎回入れる")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.hint)
                }

                Spacer(minLength: 0)

                Image(systemName: tile.amount == nil ? "pencil" : "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.backgroundTop)
                    .frame(width: Self.markSize, height: Self.markSize)
                    .background(Palette.accent, in: Circle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .templateCardFace(cornerRadius: Self.tileRadius, shadowRadius: 4)
    }

    func todayRecords(of summary: QuickRecordWidgetSummary) -> some View {
        let others = summary.todayCount - summary.todayRecords.count

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日の記録 \(summary.todayCount) 件")
                    .textFont(size: .micro)
                    .tracking(1)
                    .foregroundStyle(Palette.accent)

                Spacer(minLength: 4)

                if others > 0 {
                    Text("ほか \(others) 件")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.subtext)
                }
            }

            if summary.todayRecords.isEmpty {
                Text("今日はまだ記録していません")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.hint)
            } else {
                ForEach(summary.todayRecords) { record in
                    recordRow(record)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func recordRow(_ record: QuickRecordWidgetSummary.Record) -> some View {
        HStack(spacing: 8) {
            IconImage(record.icon, size: 11)
                .foregroundStyle(Palette.accent)
                .frame(width: Self.badgeSize, height: Self.badgeSize)
                .background(Palette.faint, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(record.title)
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Text(record.detail)
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(amountText(of: record))
                .displayFont(.small, weight: .medium)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .privacySensitive()
        }
    }
}

private extension QuickRecordWidgetView {
    static let columns = 2
    static let headerHeight: CGFloat = 20
    static let tileRadius: CGFloat = 14
    static let badgeSize: CGFloat = 20
    static let markSize: CGFloat = 20

    var isLarge: Bool {
        family == .systemLarge
    }

    var rowCount: Int {
        isLarge ? 4 : 2
    }

    func amountText(of record: QuickRecordWidgetSummary.Record) -> String {
        let text = AmountText.text(record.amount)

        return record.type == .income ? "+" + text : text
    }
}
