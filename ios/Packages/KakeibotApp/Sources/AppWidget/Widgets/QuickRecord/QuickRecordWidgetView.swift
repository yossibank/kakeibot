import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct QuickRecordWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: QuickRecordWidgetEntry

    var body: some View {
        GeometryReader { proxy in
            layout(metrics(fitting: proxy.size.height))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(route.url)
        .widgetTheme(entry.look, style: entry.style)
    }
}

private extension QuickRecordWidgetView {
    struct Metrics {
        let top: CGFloat
        let bottom: CGFloat
        let spacing: CGFloat
        let headerHeight: CGFloat
        let gridSpacing: CGFloat
        let tilePadding: CGFloat
        let todaySlots: Int
    }
}

extension QuickRecordWidgetView {
    static let badgeSize = TemplateBadge.Size.small.diameter

    var isLarge: Bool {
        family == .systemLarge
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
                    .frame(height: metrics.headerHeight)

                if summary.tiles.isEmpty {
                    emptyTemplateGuide
                } else {
                    grid(of: summary, metrics: metrics)
                }

                if isLarge {
                    Rectangle()
                        .fill(Palette.line)
                        .frame(height: 1)
                        .frame(height: Self.ruleHeight)

                    todayRecords(of: summary, metrics: metrics)
                }
            }
        } else {
            Text("アプリを開くと出ます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    func header(of summary: QuickRecordWidgetSummary) -> some View {
        if let recorded = summary.recorded(at: entry.date) {
            HStack(spacing: 8) {
                NoticeBadge(systemImage: "checkmark", size: Self.badgeSize)

                Text("\(recorded.name) \(Yen.text(recorded.amount)) を記録しました")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .privacySensitive()

                Spacer(minLength: 4)

                Button(intent: QuickRecordUndoIntent(recorded.id)) {
                    NoticeActionLabel("取り消す", height: nil)
                        .textFont(size: .caption, weight: .semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 4)
            .padding(.trailing, 2)
            .padding(.vertical, 2)
            .noticeCapsule()
        } else {
            HStack(spacing: 8) {
                Text("すぐ記録")
                    .textFont(size: .caption)
                    .tracking(1)
                    .foregroundStyle(Palette.accent)

                receiptLink

                Spacer(minLength: 4)

                Text("今日の支出 \(Yen.text(summary.todayExpense))")
                    .textFont(size: .caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .privacySensitive()
            }
        }
    }

    func grid(
        of summary: QuickRecordWidgetSummary,
        metrics: Metrics
    ) -> some View {
        let count = rowCount * Self.columns
        let visible = summary.tiles.prefix(count)
        let tiles = Array(visible)

        return Grid(horizontalSpacing: 8, verticalSpacing: metrics.gridSpacing) {
            gridRow(0, of: tiles, padding: metrics.tilePadding)

            gridRow(1, of: tiles, padding: metrics.tilePadding)

            if isLarge {
                gridRow(2, of: tiles, padding: metrics.tilePadding)
            }
        }
    }

    func gridRow(
        _ row: Int,
        of tiles: [QuickRecordWidgetSummary.Tile],
        padding: CGFloat
    ) -> some View {
        let first = row * Self.columns

        return GridRow {
            gridCell(at: first, of: tiles, padding: padding)

            gridCell(at: first + 1, of: tiles, padding: padding)
        }
    }

    @ViewBuilder
    func gridCell(
        at index: Int,
        of tiles: [QuickRecordWidgetSummary.Tile],
        padding: CGFloat
    ) -> some View {
        if index < tiles.count {
            tileButton(tiles[index], padding: padding)
        } else if index == tiles.count {
            entryTileLink(padding: padding)
        } else {
            Color.clear
        }
    }

    func todayRecords(
        of summary: QuickRecordWidgetSummary,
        metrics: Metrics
    ) -> some View {
        let shown = summary.todayRecords.prefix(metrics.todaySlots)
        let records = Array(shown)
        let others = summary.todayCount - records.count

        return VStack(alignment: .leading, spacing: Self.todaySpacing) {
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
            .frame(height: Self.todayTitleHeight)

            VStack(spacing: Self.todaySpacing) {
                ForEach(0..<metrics.todaySlots, id: \.self) { index in
                    todaySlot(at: index, of: records)
                        .frame(height: Self.recordRowHeight)
                }
            }
            .overlay(alignment: .leading) {
                if records.isEmpty {
                    Text("今日はまだ記録していません")
                        .textFont(size: .caption)
                        .foregroundStyle(Palette.hint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func todaySlot(
        at index: Int,
        of records: [QuickRecordWidgetSummary.Record]
    ) -> some View {
        if index < records.count {
            recordRow(records[index])
        } else {
            Color.clear
        }
    }

    func recordRow(_ record: QuickRecordWidgetSummary.Record) -> some View {
        HStack(spacing: 8) {
            IconTile(record.icon, size: Self.recordIconSize)

            VStack(alignment: .leading, spacing: 1) {
                Text(record.title)
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(record.detail)
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Spacer(minLength: 8)

            AmountText(record.amount, type: record.type, font: .size(.small, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .privacySensitive()
        }
    }
}

private extension QuickRecordWidgetView {
    static let columns = 2
    static let todayTitleHeight: CGFloat = 14
    static let recordRowHeight: CGFloat = 30
    static let todaySpacing: CGFloat = 8
    static let ruleHeight: CGFloat = 17

    static let regular = Metrics(
        top: 12,
        bottom: 16,
        spacing: 4,
        headerHeight: 32,
        gridSpacing: 8,
        tilePadding: 8,
        todaySlots: 2
    )

    static let tight = Metrics(
        top: 8,
        bottom: 8,
        spacing: 4,
        headerHeight: 28,
        gridSpacing: 8,
        tilePadding: 8,
        todaySlots: 2
    )

    static let compact = Metrics(
        top: 8,
        bottom: 8,
        spacing: 4,
        headerHeight: 24,
        gridSpacing: 4,
        tilePadding: 4,
        todaySlots: 2
    )

    var route: PlannedNotification.Route {
        entry.summary?.tiles.isEmpty == true ? .newTemplate : .home
    }

    var rowCount: Int {
        isLarge ? 3 : 2
    }

    var tileContentHeight: CGFloat {
        isLarge ? 40 : 26
    }

    func metrics(fitting height: CGFloat) -> Metrics {
        let candidates = [
            Self.regular,
            Self.tight,
            Self.tight.limited(1),
            Self.compact,
            Self.compact.limited(1)
        ]

        let fitting = candidates.first { requiredHeight(of: $0) <= height }

        return fitting ?? Self.compact.limited(1)
    }

    func requiredHeight(of metrics: Metrics) -> CGFloat {
        let rows = CGFloat(rowCount)
        let tiles = rows * (tileContentHeight + metrics.tilePadding * 2)
        let grid = tiles + (rows - 1) * metrics.gridSpacing
        let base = metrics.top + metrics.headerHeight + metrics.spacing + grid + metrics.bottom

        guard isLarge else {
            return base
        }

        let slots = CGFloat(metrics.todaySlots)
        let rule = Self.ruleHeight + metrics.spacing * 2
        let records = slots * Self.recordRowHeight + (slots - 1) * Self.todaySpacing

        return base + rule + Self.todayTitleHeight + Self.todaySpacing + records
    }
}

private extension QuickRecordWidgetView.Metrics {
    func limited(_ count: Int) -> Self {
        Self(
            top: top,
            bottom: bottom,
            spacing: spacing,
            headerHeight: headerHeight,
            gridSpacing: gridSpacing,
            tilePadding: tilePadding,
            todaySlots: count
        )
    }
}
