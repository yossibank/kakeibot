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
        let start = try #require(LocalDate("2026-11-01"))
        let end = try #require(LocalDate("2026-11-30"))
        let today = try #require(LocalDate("2026-11-21"))
        let closing = try #require(LocalDate("2026-12-01"))

        let budget = ReviewPace(
            limit: 150_000,
            basis: .budget,
            spent: 98400,
            range: start...end,
            today: today
        )

        let over = ReviewPace(
            limit: 120_000,
            basis: .average(periods: 2),
            spent: 131_000,
            range: start...end,
            today: today
        )

        let exceeded = ReviewPace(
            limit: 200_000,
            basis: .budget,
            spent: 2_074_020,
            range: start...end,
            today: today
        )

        let goal = ReviewGoal(
            period: "month:2026-11-01",
            kind: .count,
            categoryId: nil,
            memo: "外食",
            baseline: 9,
            target: 7,
            saving: 6000,
            createdAt: Date()
        )

        let item = ReviewGoalItem(
            goal: goal,
            name: "外食",
            categoryName: "食費",
            progress: ReviewGoal.Progress(
                count: 6,
                amount: 9000,
                projectedCount: 8,
                elapsedRatio: 0.7
            )
        )

        let totals = [
            182_000,
            164_500,
            171_000,
            158_200,
            149_800,
            176_300,
            203_400,
            168_900,
            155_000,
            160_200,
            98400,
            0
        ]

        let months = totals.enumerated().map { index, total in
            let state: ReviewYearProgress.State = if index < 10 {
                .closed
            } else if index == 10 {
                .current
            } else {
                .upcoming
            }

            return ReviewYearProgress.Month(
                id: index,
                range: closing...closing,
                name: "\(index + 1)月",
                total: total,
                state: state,
                isWithinBudget: index < 10 ? total <= 170_000 : nil
            )
        }

        let year = ReviewYearProgress(months: months, spent: 1_787_700, previousSpent: 1_842_000)

        let cases: [(String, ReviewPace?, ReviewYearProgress?, [ReviewGoalItem])] = [
            ("budget", budget, nil, [item]),
            ("average", over, nil, []),
            ("exceeded", exceeded, nil, []),
            ("first", nil, nil, []),
            ("year", nil, year, [])
        ]

        for variant in Self.variants {
            for (name, pace, year, goals) in cases {
                let view = ReviewProgressView(
                    pace: pace,
                    year: year,
                    unit: "月",
                    currentName: "今月",
                    goals: goals,
                    closingTitle: "11月のふりかえり",
                    closingDate: closing,
                    closingDaysLeft: 10,
                    nextGoalTitle: "12月の一手",
                    previousTitle: "10月のふりかえりを見る",
                    onOpenPrevious: {},
                    onOpenMonth: { _ in }
                )
                .padding(16)

                try Self.write(view, variant: variant, to: "review-progress-\(name)")
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
