@testable import AppWidget
import Core
import DesignSystem
import SwiftUI
import Testing
import UIKit
import WidgetKit

@MainActor
struct SnapshotTests {
    @Test
    func render() throws {
        let today = LocalDate(Date(), in: .current)

        for (name, summary) in Self.cases(on: today) {
            let entry = BudgetWidgetEntry(
                date: Date(),
                summary: summary,
                look: .followsDevice,
                style: .standard
            )

            for shape in Self.shapes {
                let view = shape.view(entry)
                    .frame(width: shape.size.width, height: shape.size.height)
                    .background(shape.background)

                try Self.write(view, to: "\(name)-\(shape.name).png")
            }
        }

        for (name, summary) in Self.quickCases() {
            let entry = QuickRecordWidgetEntry(
                date: Date(),
                summary: summary,
                look: .followsDevice,
                style: .standard
            )

            for (shape, size) in Self.quickShapes {
                let view = QuickRecordWidgetView(entry: entry, family: shape)
                    .frame(width: size.width, height: size.height)
                    .background(Color(white: 0.97))

                let width = Int(size.width)
                let height = Int(size.height)
                let fileName = "quick-\(name)-\(width)x\(height).png"

                try Self.write(view, to: fileName)
            }
        }
    }
}

extension SnapshotTests {
    struct Shape {
        let name: String
        let size: CGSize
        let background: Color
        let view: (BudgetWidgetEntry) -> AnyView
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"

    static let shapes: [Shape] = [
        home("small", .systemSmall, CGSize(width: 170, height: 170)),
        home("medium", .systemMedium, CGSize(width: 364, height: 170)),
        lock("circular", .accessoryCircular, CGSize(width: 76, height: 76)),
        lock("rectangular", .accessoryRectangular, CGSize(width: 172, height: 76)),
        lock("inline", .accessoryInline, CGSize(width: 260, height: 24))
    ]

    static let quickShapes: [(WidgetFamily, CGSize)] = [
        (.systemMedium, CGSize(width: 364, height: 170)),
        (.systemLarge, CGSize(width: 364, height: 382)),
        (.systemMedium, CGSize(width: 329, height: 155)),
        (.systemLarge, CGSize(width: 329, height: 345)),
        (.systemMedium, CGSize(width: 321, height: 148)),
        (.systemLarge, CGSize(width: 321, height: 324))
    ]

    static func quickCases() -> [(String, QuickRecordWidgetSummary)] {
        let sample = QuickRecordWidgetSummary.sample()
        let until = Date().addingTimeInterval(60)

        let recorded = QuickRecordWidgetSummary.Recorded(
            id: Entry.ID(),
            name: "ランチ",
            amount: 980,
            until: until
        )

        let undo = QuickRecordWidgetSummary(
            todayExpense: sample.todayExpense,
            tiles: sample.tiles,
            todayRecords: sample.todayRecords,
            todayCount: sample.todayCount,
            recorded: recorded
        )

        let longTiles = sample.tiles.map { tile in
            QuickRecordWidgetSummary.Tile(
                id: tile.id,
                name: "子どもの習い事の月謝まとめ払い",
                detail: "子どもの習い事・みずほ銀行",
                amount: tile.amount.map { $0 * 10000 },
                icon: tile.icon
            )
        }

        let longRecords = sample.todayRecords.map { record in
            QuickRecordWidgetSummary.Record(
                id: record.id,
                title: "子どもの習い事と教材と遠征費",
                detail: "発表会の衣装と靴・みずほ銀行",
                amount: record.amount * 10000,
                type: record.type,
                icon: record.icon
            )
        }

        let long = QuickRecordWidgetSummary(
            todayExpense: 12_345_678,
            tiles: longTiles,
            todayRecords: longRecords,
            todayCount: sample.todayCount,
            recorded: nil
        )

        return [("normal", sample), ("undo", undo), ("long", long)]
    }

    static func cases(on today: LocalDate) -> [(String, BudgetWidgetSummary?)] {
        let periodEnd = today.adding(days: 8)

        let over = BudgetUsage(
            budget: 90000,
            spent: 93000,
            today: today,
            periodEnd: periodEnd
        )

        let overSummary = BudgetWidgetSummary(
            usage: over,
            monthExpense: over.spent,
            todayExpense: 1200,
            yesterdayExpense: 2300,
            weekExpense: 12000,
            nextRecurring: nil
        )

        let noBudget = BudgetWidgetSummary(
            usage: nil,
            monthExpense: 58000,
            todayExpense: 1200,
            yesterdayExpense: 2300,
            weekExpense: 9000,
            nextRecurring: nil
        )

        let huge = BudgetUsage(
            budget: 12_000_000,
            spent: 9_876_543,
            today: today,
            periodEnd: periodEnd
        )

        let hugeSummary = BudgetWidgetSummary(
            usage: huge,
            monthExpense: huge.spent,
            todayExpense: 1_234_567,
            yesterdayExpense: 2_345_678,
            weekExpense: 8_765_432,
            nextRecurring: nil
        )

        return [
            ("normal", .sample(on: today)),
            ("huge", hugeSummary),
            ("over", overSummary),
            ("nobudget", noBudget),
            ("empty", nil)
        ]
    }

    static func home(
        _ name: String,
        _ family: WidgetFamily,
        _ size: CGSize
    ) -> Shape {
        let background = Color(white: 0.97)

        return Shape(name: name, size: size, background: background) { entry in
            AnyView(BudgetWidgetView(entry: entry, family: family))
        }
    }

    static func lock(
        _ name: String,
        _ family: WidgetFamily,
        _ size: CGSize
    ) -> Shape {
        let background = Color(white: 0.2)

        return Shape(name: name, size: size, background: background) { entry in
            AnyView(
                BudgetLockWidgetView(entry: entry, family: family)
                    .environment(\.colorScheme, .dark)
            )
        }
    }

    static func write(
        _ view: some View,
        to name: String
    ) throws {
        let renderer = ImageRenderer(content: view)

        renderer.scale = 2

        let data = try #require(renderer.uiImage?.pngData())
        let url = URL(fileURLWithPath: directory).appending(path: name)

        try data.write(to: url)
    }
}
