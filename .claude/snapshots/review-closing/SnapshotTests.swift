import Core
@testable import DesignSystem
@testable import Features
import SwiftUI
import Testing
import UIKit

@MainActor
struct SnapshotTests {
    @Test
    func render() throws {
        let start = try #require(LocalDate("2026-10-01"))
        let end = try #require(LocalDate("2026-10-31"))
        let range = start...end
        let wallet = Wallet.ID()
        let now = Date()
        let skipped: Set = [5, 12, 26]

        let entries = (1...31).filter { !skipped.contains($0) }.map { day in
            Entry(
                type: .expense,
                amount: 1000,
                date: start.adding(days: day - 1),
                categoryId: nil,
                walletId: wallet,
                createdAt: now,
                updatedAt: now
            )
        }

        let streak = ReviewStreak(entries: entries, in: range)

        let budget = ReviewPace(
            limit: 150_000,
            basis: .budget,
            spent: 138_000,
            range: range,
            today: end
        )

        let over = ReviewPace(
            limit: 120_000,
            basis: .average(periods: 2),
            spent: 141_000,
            range: range,
            today: end
        )

        let rows = [
            ReviewClosingView.CompareRow(
                name: "食費",
                row: ReviewCompare.Row(
                    categoryId: EntryCategory.ID(),
                    amount: 41200,
                    average: 32500
                )
            ),
            ReviewClosingView.CompareRow(
                name: "日用品",
                row: ReviewCompare.Row(categoryId: EntryCategory.ID(), amount: 6100, average: 8400)
            ),
            ReviewClosingView.CompareRow(
                name: "交際費",
                row: ReviewCompare.Row(
                    categoryId: EntryCategory.ID(),
                    amount: 12000,
                    average: 11500
                )
            )
        ]

        let special = ReviewClosingView.Special(
            date: start.adding(days: 7),
            name: "冷蔵庫",
            amount: 32000
        )

        let cases: [(String, ReviewPeriod.Scale, ReviewPace?, Bool)] = [
            ("budget", .month, budget, true),
            ("average", .month, over, false),
            ("first", .month, nil, false),
            ("week", .week, budget, true)
        ]

        for variant in Self.variants {
            for (name, scale, pace, isFull) in cases {
                let content = ReviewClosingView.Content(
                    scale: scale,
                    range: range,
                    weekStart: .sunday,
                    pace: pace,
                    spent: pace?.spent ?? 52000,
                    previousTotal: isFull ? 146_400 : nil,
                    rows: isFull ? rows : [],
                    averagePeriods: 3,
                    special: isFull ? special : nil,
                    streak: streak,
                    continuing: 5,
                    budgetStreak: isFull ? 3 : 0
                )

                let view = ReviewClosingView(
                    content: content,
                    name: "10月",
                    previousName: "9月",
                    unit: "月"
                )
                .padding(16)

                try Self.write(view, variant: variant, to: "review-closing-\(name)")
            }
        }
    }
}

extension SnapshotTests {
    struct Variant {
        let name: String
        let width: CGFloat
        let scheme: ColorScheme
        let textSize: ThemeTextSize
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let maxHeight: CGFloat = 2400

    static let variants = [
        Variant(name: "regular", width: 393, scheme: .dark, textSize: .standard),
        Variant(name: "light", width: 393, scheme: .light, textSize: .standard),
        Variant(name: "narrow", width: 320, scheme: .light, textSize: .large)
    ]

    static func write(
        _ view: some View,
        variant: Variant,
        to name: String
    ) throws {
        let style = ThemeStyle(
            corner: .standard,
            displayFont: .mincho,
            textFont: .gothic,
            textSize: variant.textSize
        )

        let preset: ThemePreset = variant.scheme == .dark ? .black : .white

        let content = view
            .frame(width: variant.width)
            .frame(maxHeight: maxHeight, alignment: .top)
            .clipped()
            .background(Palette.background)
            .environment(\.themeStyle, style)
            .environment(\.palette, preset.palette)
            .environment(\.colorScheme, variant.scheme)

        let renderer = ImageRenderer(content: content)

        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: variant.width, height: nil)

        let data = try #require(renderer.uiImage?.pngData())
        let url = URL(fileURLWithPath: directory).appending(path: "\(name)-\(variant.name).png")

        try data.write(to: url)
    }
}
