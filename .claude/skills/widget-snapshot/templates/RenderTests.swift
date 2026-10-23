@testable import AppWidget
import Core
import DesignSystem
import SwiftUI
import Testing
import UIKit
import WidgetKit

@MainActor
struct RenderTests {
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
    }
}

extension RenderTests {
    struct Shape {
        let name: String
        let size: CGSize
        let background: Color
        let view: (BudgetWidgetEntry) -> AnyView
    }
}

private extension RenderTests {
    static let directory = "__OUT__"

    static let shapes: [Shape] = [
        home("small", .systemSmall, CGSize(width: 170, height: 170)),
        home("medium", .systemMedium, CGSize(width: 364, height: 170)),
        lock("circular", .accessoryCircular, CGSize(width: 76, height: 76)),
        lock("rectangular", .accessoryRectangular, CGSize(width: 172, height: 76)),
        lock("inline", .accessoryInline, CGSize(width: 260, height: 24))
    ]

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

        return [
            ("normal", .sample(on: today)),
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
        Shape(name: name, size: size, background: Color(white: 0.97)) { entry in
            AnyView(BudgetWidgetView(entry: entry, family: family))
        }
    }

    static func lock(
        _ name: String,
        _ family: WidgetFamily,
        _ size: CGSize
    ) -> Shape {
        Shape(name: name, size: size, background: Color(white: 0.2)) { entry in
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
