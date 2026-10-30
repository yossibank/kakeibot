import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct QuickRecordWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: QuickRecordWidgetEntry

    var body: some View {
        ViewThatFits(in: .vertical) {
            layout(Self.regular)

            layout(Self.tight)

            layout(Self.tight.limited(2))

            layout(Self.tight.limited(1))

            layout(Self.compact.limited(2))

            layout(Self.compact.limited(1))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(PlannedNotification.Route.home.url)
        .widgetTheme(entry.look, style: entry.style)
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
                        .padding(.vertical, 8)

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
            HStack(spacing: 8) {
                NoticeMark(systemImage: "checkmark", size: Self.badgeSize)

                Text("\(recorded.name) \(AmountText.text(recorded.amount)) を記録しました")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .privacySensitive()

                Spacer(minLength: 4)

                Button(intent: UndoWidgetEntryIntent(recorded.id)) {
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
                    .minimumScaleFactor(0.5)
                    .privacySensitive()
            }
            .frame(maxHeight: .infinity)
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
        } else {
            Color.clear
        }
    }

    func todayRecords(
        of summary: QuickRecordWidgetSummary,
        limit: Int
    ) -> some View {
        let shown = summary.todayRecords.prefix(limit)
        let records = Array(shown)
        let others = summary.todayCount - records.count

        return VStack(alignment: .leading, spacing: 8) {
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

            if let first = records.first {
                recordRow(first)
            } else {
                Text("今日はまだ記録していません")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.hint)
            }

            if let second = records.dropFirst().first {
                recordRow(second)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func recordRow(_ record: QuickRecordWidgetSummary.Record) -> some View {
        HStack(spacing: 8) {
            TemplateBadge(icon: record.icon, size: .small)

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

            AmountText(record.amount, type: record.type)
                .displayFont(.small, weight: .medium)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
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

    static let regular = Metrics(
        top: 12,
        bottom: 16,
        spacing: 4,
        headerHeight: 20,
        undoHeaderHeight: 32,
        gridSpacing: 8,
        tilePadding: 8,
        todayLimit: .max
    )

    static let tight = Metrics(
        top: 8,
        bottom: 8,
        spacing: 4,
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
        gridSpacing: 4,
        tilePadding: 4,
        todayLimit: .max
    )

    var rowCount: Int {
        isLarge ? 3 : 2
    }

    func headerMaxHeight(
        of summary: QuickRecordWidgetSummary,
        metrics: Metrics
    ) -> CGFloat {
        summary.recorded(at: entry.date) == nil ? metrics.headerHeight : metrics.undoHeaderHeight
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
