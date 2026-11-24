import Core
@testable import DesignSystem
@testable import Features
import SwiftUI
import Testing
import UIKit

private let snapshotNow = Date(timeIntervalSince1970: 1_791_774_000)

@MainActor
struct SnapshotTests {
    @Test
    func render() throws {
        let start = try #require(LocalDate("2026-10-01"))
        let end = try #require(LocalDate("2026-10-31"))
        let range = start...end
        let wallet = Wallet.ID()
        let now = snapshotNow
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

        let noSpendDays: Set = [start.adding(days: 4), start.adding(days: 11)]
        let streak = ReviewStreak(entries: entries, noSpendDays: noSpendDays, in: range)

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
            ReviewClosing.CompareRow(
                name: "食費",
                row: ReviewCompare.Row(
                    categoryId: EntryCategory.ID(),
                    amount: 41200,
                    average: 32500
                )
            ),
            ReviewClosing.CompareRow(
                name: "日用品",
                row: ReviewCompare.Row(categoryId: EntryCategory.ID(), amount: 6100, average: 8400)
            ),
            ReviewClosing.CompareRow(
                name: "交際費",
                row: ReviewCompare.Row(
                    categoryId: EntryCategory.ID(),
                    amount: 12000,
                    average: 11500
                )
            )
        ]

        let special = ReviewClosing.Special(
            date: start.adding(days: 7),
            name: "冷蔵庫",
            amount: 32000
        )

        let answer = ReviewGoalItem(
            goal: ReviewGoal(
                period: "month:2026-10-01",
                kind: .count,
                categoryId: EntryCategory.ID(),
                memo: "外食",
                baseline: 9,
                target: 7,
                saving: 3000,
                result: 6,
                saved: 4500,
                createdAt: snapshotNow,
                checkedAt: snapshotNow
            ),
            name: "外食",
            categoryName: "食費",
            progress: ReviewGoal.Progress(
                count: 6,
                amount: 9000,
                projectedCount: 6,
                elapsedRatio: 1
            )
        )

        let next = ReviewGoalItem(
            goal: ReviewGoal(
                period: "month:2026-11-01",
                kind: .average,
                categoryId: EntryCategory.ID(),
                baseline: 2400,
                target: 1800,
                saving: 4800,
                createdAt: snapshotNow
            ),
            name: "日用品",
            categoryName: "日用品",
            progress: ReviewGoal.Progress(
                count: 0,
                amount: 0,
                projectedCount: 0,
                elapsedRatio: 0
            )
        )

        let reason = ReviewClosing.Reason(
            text: "10月は日用品をまとめて買った日が多く、1 回の平均が 2,400円 になりました。",
            isWritten: true
        )

        let goalCases: [String: (ReviewGoalItem?, ReviewClosing.Next)] = [
            "budget": (answer, .goal(next, reason: reason)),
            "average": (nil, .rest)
        ]

        let cases: [(String, String, ReviewPeriod.Scale, ReviewPace?, Bool)] = [
            ("budget", "予算がある月", .month, budget, true),
            ("average", "予算がなく直近の平均と比べる月", .month, over, false),
            ("first", "初めての月", .month, nil, false),
            ("week", "週", .week, budget, true)
        ]

        for variant in Self.variants {
            for (name, title, scale, pace, isFull) in cases {
                let weekRange = start.adding(days: 3)...start.adding(days: 9)
                let shownRange = scale == .week ? weekRange : range

                let content = ReviewClosing.Content(
                    scale: scale,
                    range: shownRange,
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

                let goalCase = goalCases[name]

                let goals = ReviewClosing.Goals(
                    answer: goalCase?.0,
                    next: goalCase?.1 ?? .none,
                    nextName: "11月",
                    nextStart: range.upperBound.adding(days: 1),
                    checkDate: range.upperBound.adding(days: 31)
                )

                let whys = Dictionary(uniqueKeysWithValues: rows.prefix(1)
                    .map { ($0.id, Self.why) })
                let notes = ReviewClosing.Notes(summary: Self.summary, whys: whys)

                let view = ReviewClosingView(
                    content: content,
                    goals: goals,
                    notes: isFull ? notes : .empty,
                    name: "10月",
                    previousName: "9月",
                    unit: "月",
                    onOpenGoal: { _ in },
                    onOpenWhy: { _, _ in }
                )
                .padding(16)

                try Self.write(
                    view,
                    variant: variant,
                    title: "締めのレポート › \(title)",
                    to: "review-closing-\(name)"
                )
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

        var label: String {
            var parts = ["幅 \(Int(width))", scheme == .dark ? "ダーク" : "ライト"]

            switch textSize {
            case .standard: break
            case .small: parts.append("文字小")
            case .large: parts.append("文字大")
            }

            return parts.joined(separator: "・")
        }
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let summary = "予算内で締めました。食費が多めでしたが、日用品を抑えられています。"
    static let why = ReviewCompare.Why(
        parts: [
            .text("「外食」の記録が "),
            .number("6"),
            .text(" 件あり、"),
            .number("18"),
            .text(" 件のうち "),
            .number("11"),
            .text(" 件が土日でした。")
        ],
        memo: "外食"
    )
    static let maxHeight: CGFloat = 2400

    static let variants = [
        Variant(name: "regular", width: 393, scheme: .dark, textSize: .standard),
        Variant(name: "light", width: 393, scheme: .light, textSize: .standard),
        Variant(name: "narrow", width: 320, scheme: .light, textSize: .large)
    ]

    static func write(
        _ view: some View,
        variant: Variant,
        title: String,
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

        try SnapshotIndex.record(
            directory: directory,
            file: "\(name)-\(variant.name).png",
            title: title,
            variant: variant.label
        )
    }
}
