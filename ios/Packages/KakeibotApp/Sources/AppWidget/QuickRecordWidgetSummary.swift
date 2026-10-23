import Core
import Foundation
import Store

struct QuickRecordWidgetSummary: Hashable, Sendable {
    let todayExpense: Int
    let tiles: [Tile]
    let recorded: Recorded?
}

extension QuickRecordWidgetSummary {
    struct Tile: Hashable, Identifiable, Sendable {
        let id: EntryTemplate.ID
        let name: String
        let amount: Int
        let icon: Icon?
    }

    struct Recorded: Hashable, Sendable {
        let id: Entry.ID
        let name: String
        let amount: Int
        let until: Date
    }

    static let limit = 8
    static let undoInterval: TimeInterval = 60

    init(
        _ overview: MonthOverview,
        templates: [EntryTemplate],
        order: TemplateOrder,
        recordedId: Entry.ID?
    ) {
        let list = overview.list
        let usable = templates.filter { $0.type == .expense && $0.amount != nil }
        let ordered = list?.ordered(usable, by: order, today: overview.today) ?? usable

        let tiles = ordered.prefix(Self.limit).compactMap { template in
            template.amount.map { amount in
                Tile(
                    id: template.id,
                    name: template.name,
                    amount: amount,
                    icon: list?.icon(for: template)
                )
            }
        }

        let entry = recordedId.flatMap { id in
            list?.days
                .lazy
                .flatMap(\.entries)
                .first { $0.id == id }
        }

        let recorded = entry.map { entry in
            let template = templates.first { $0.id == entry.templateId }
            let category = entry.categoryId.flatMap { list?.categories[$0] }

            return Recorded(
                id: entry.id,
                name: template?.name ?? category?.name ?? "記録",
                amount: entry.amount,
                until: entry.createdAt.addingTimeInterval(Self.undoInterval)
            )
        }

        self.init(
            todayExpense: overview.todayExpense,
            tiles: Array(tiles),
            recorded: recorded
        )
    }

    static func sample() -> QuickRecordWidgetSummary {
        let tiles = [
            ("コーヒー", 450),
            ("ランチ", 980),
            ("電車", 220),
            ("コンビニ", 500),
            ("本", 1500),
            ("ジム", 800),
            ("おやつ", 300),
            ("日用品", 1200)
        ].map { name, amount in
            Tile(id: EntryTemplate.ID(), name: name, amount: amount, icon: nil)
        }

        return QuickRecordWidgetSummary(
            todayExpense: 1120,
            tiles: tiles,
            recorded: nil
        )
    }

    func recorded(at date: Date) -> Recorded? {
        recorded.flatMap { $0.until > date ? $0 : nil }
    }

    func clearingRecorded() -> QuickRecordWidgetSummary {
        QuickRecordWidgetSummary(
            todayExpense: todayExpense,
            tiles: tiles,
            recorded: nil
        )
    }
}
