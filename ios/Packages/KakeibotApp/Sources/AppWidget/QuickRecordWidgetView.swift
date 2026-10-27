import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct QuickRecordWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: QuickRecordWidgetEntry

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(Self.layouts.indices, id: \.self) { index in
                layout(Self.layouts[index])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(PlannedNotification.Route.home.url)
        .widgetTheme(entry.look, style: entry.style)
    }
}

private extension QuickRecordWidgetView {
    func layout(_ metrics: Metrics) -> some View {
        content(metrics)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 16)
            .padding(.top, metrics.top)
            .padding(.bottom, metrics.bottom)
    }

    @ViewBuilder
    func content(_ metrics: Metrics) -> some View {
        if let summary = entry.summary {
            VStack(spacing: metrics.spacing) {
                header(of: summary)
                    .frame(
                        minHeight: metrics.headerHeight,
                        maxHeight: headerMaxHeight(of: summary, metrics: metrics)
                    )
                    .layoutPriority(1)

                if summary.tiles.isEmpty {
                    Text("テンプレートを作ると、ここから記録できます")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    grid(of: summary, metrics: metrics)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if isLarge {
                    Rectangle()
                        .fill(Palette.line)
                        .frame(height: 1)

                    todayRecords(of: summary, limit: metrics.todayLimit)
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
                        .lineLimit(1)
                        .fixedSize()
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

    func grid(
        of summary: QuickRecordWidgetSummary,
        metrics: Metrics
    ) -> some View {
        let tiles = Array(summary.tiles.prefix(rowCount * Self.columns))

        return Grid(horizontalSpacing: 8, verticalSpacing: metrics.gridSpacing) {
            ForEach(0..<rowCount, id: \.self) { row in
                GridRow {
                    ForEach(0..<Self.columns, id: \.self) { column in
                        let index = row * Self.columns + column

                        if index < tiles.count {
                            tileButton(tiles[index], padding: metrics.tilePadding)
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

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

    func tileFace(
        _ tile: QuickRecordWidgetSummary.Tile,
        padding: CGFloat
    ) -> some View {
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
            }

            if isLarge {
                Text(tile.detail)
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .padding(.leading, Self.badgeSize + 6)
            }

            Spacer(minLength: 0)

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
        .padding(.vertical, padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .templateCardFace(cornerRadius: Self.tileRadius, shadowRadius: 4)
    }

    func todayRecords(
        of summary: QuickRecordWidgetSummary,
        limit: Int
    ) -> some View {
        let records = Array(summary.todayRecords.prefix(limit))
        let others = summary.todayCount - records.count

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

            if records.isEmpty {
                Text("今日はまだ記録していません")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.hint)
            } else {
                ForEach(records) { record in
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
    struct Metrics {
        let top: CGFloat
        let bottom: CGFloat
        let spacing: CGFloat
        let headerHeight: CGFloat
        let undoHeaderHeight: CGFloat
        let gridSpacing: CGFloat
        let tilePadding: CGFloat
        let todayLimit: Int
    }

    static let columns = 2
    static let layouts = [
        regular,
        tight,
        tight.limited(2),
        tight.limited(1),
        compact.limited(2),
        compact.limited(1)
    ]
    static let tileRadius: CGFloat = 14
    static let badgeSize: CGFloat = 20
    static let markSize: CGFloat = 20
    static let regular = Metrics(
        top: 12,
        bottom: 18,
        spacing: 6,
        headerHeight: 20,
        undoHeaderHeight: 32,
        gridSpacing: 8,
        tilePadding: 8,
        todayLimit: .max
    )

    static let tight = Metrics(
        top: 8,
        bottom: 8,
        spacing: 6,
        headerHeight: 20,
        undoHeaderHeight: 28,
        gridSpacing: 8,
        tilePadding: 8,
        todayLimit: .max
    )

    static let compact = Metrics(
        top: 8,
        bottom: 8,
        spacing: 4,
        headerHeight: 16,
        undoHeaderHeight: 24,
        gridSpacing: 6,
        tilePadding: 4,
        todayLimit: .max
    )

    var isLarge: Bool {
        family == .systemLarge
    }

    var rowCount: Int {
        isLarge ? 3 : 2
    }

    func headerMaxHeight(
        of summary: QuickRecordWidgetSummary,
        metrics: Metrics
    ) -> CGFloat {
        summary.recorded(at: entry.date) == nil ? metrics.headerHeight : metrics.undoHeaderHeight
    }

    func amountText(of record: QuickRecordWidgetSummary.Record) -> String {
        let text = AmountText.text(record.amount)
        return record.type == .income ? "+" + text : text
    }
}

private extension QuickRecordWidgetView.Metrics {
    func limited(_ count: Int) -> Self {
        Self(
            top: top,
            bottom: bottom,
            spacing: spacing,
            headerHeight: headerHeight,
            undoHeaderHeight: undoHeaderHeight,
            gridSpacing: gridSpacing,
            tilePadding: tilePadding,
            todayLimit: count
        )
    }
}
