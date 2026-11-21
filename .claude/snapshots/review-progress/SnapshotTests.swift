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
            progress: ReviewGoal.Progress(count: 6, amount: 9000, projectedCount: 8)
        )

        let cases: [(String, ReviewPace?, [ReviewGoalItem])] = [
            ("budget", budget, [item]),
            ("average", over, []),
            ("first", nil, [])
        ]

        for variant in Self.variants {
            for (name, pace, goals) in cases {
                let view = ReviewProgressView(
                    pace: pace,
                    unit: "月",
                    currentName: "今月",
                    goals: goals,
                    closingTitle: "11月のふりかえり",
                    closingDate: closing,
                    nextGoalTitle: "12月の一手",
                    previousTitle: "10月のふりかえりを見る",
                    onOpenPrevious: {}
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
