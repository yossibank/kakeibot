import Foundation

public struct ReviewBreakdown: Hashable, Sendable {
    public let insights: [ReviewInsight]
    public let summary: Summary
}

public extension ReviewBreakdown {
    struct Spend: Hashable, Sendable {
        public let category: String
        public let memo: String?
        public let amount: Int

        public init(
            category: String,
            memo: String?,
            amount: Int
        ) {
            self.category = category
            self.memo = memo
            self.amount = amount
        }
    }

    struct Row: Codable, Hashable, Sendable {
        public let name: String
        public let count: Int
        public let previousCount: Int
        public let amount: Int
        public let previousAmount: Int?

        public init(
            name: String,
            count: Int,
            previousCount: Int,
            amount: Int,
            previousAmount: Int? = nil
        ) {
            self.name = name
            self.count = count
            self.previousCount = previousCount
            self.amount = amount
            self.previousAmount = previousAmount
        }
    }

    struct Focus: Codable, Hashable, Sendable {
        public let name: String
        public let count: Int
        public let previousCount: Int
        public let amount: Int
        public let previousAmount: Int

        public init(
            name: String,
            count: Int,
            previousCount: Int,
            amount: Int,
            previousAmount: Int
        ) {
            self.name = name
            self.count = count
            self.previousCount = previousCount
            self.amount = amount
            self.previousAmount = previousAmount
        }
    }

    struct Action: Codable, Hashable, Sendable {
        public let lead: String
        public let amount: Int

        public init(
            lead: String,
            amount: Int
        ) {
            self.lead = lead
            self.amount = amount
        }
    }

    struct Summary: Codable, Hashable, Sendable {
        public let focus: Focus
        public let rows: [Row]
        public let goodPoint: String?
        public let action: Action?

        public init(
            focus: Focus,
            rows: [Row],
            goodPoint: String?,
            action: Action?
        ) {
            self.focus = focus
            self.rows = rows
            self.goodPoint = goodPoint
            self.action = action
        }
    }

    struct Input: Hashable, Sendable {
        public let category: String
        public let scale: ReviewPeriod.Scale
        public let isCurrent: Bool
        public let hasPrevious: Bool
        public let current: [Spend]
        public let previous: [Spend]

        public init(
            category: String,
            scale: ReviewPeriod.Scale,
            isCurrent: Bool,
            hasPrevious: Bool,
            current: [Spend],
            previous: [Spend]
        ) {
            self.category = category
            self.scale = scale
            self.isCurrent = isCurrent
            self.hasPrevious = hasPrevious
            self.current = current
            self.previous = previous
        }
    }

    static let minimumCount = 3
    static let maximumRows = 3

    var names: [String] {
        summary.rows.map(\.name)
    }

    var suggestion: String? {
        summary.action?.sentence
    }

    static func normalized(_ memo: String?) -> String? {
        let trimmed = memo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed.precomposedStringWithCompatibilityMapping
    }

    static func make(from input: Input) -> ReviewBreakdown? {
        let categories = tallies(of: input) { $0.category }

        guard let target = categories.first(where: { $0.name == input.category }) else {
            return nil
        }

        guard target.count >= minimumCount || isRising(target, in: input) else {
            return nil
        }

        let unit = input.scale.unitName
        let memos = memoTallies(of: input)
        var insights: [ReviewInsight] = []
        var action: Action?
        var goodPoint: String?

        if input.hasPrevious,
           target.previousCount > 0,
           target.amount > target.previousAmount,
           let fact = change(of: target, unit: unit) {
            insights.append(ReviewInsight(kind: .increase, weight: 0, fact: fact, suggestions: []))
            action = saving(of: target, unit: unit, isCurrent: input.isCurrent)

            if let reason = reason(in: memos, for: target) {
                insights.append(reason)
            }
        }

        if !input.hasPrevious {
            insights.append(pace(of: target))
        }

        if input.hasPrevious,
           let fewer = fewer(in: categories, except: target.name) {
            let decrease = decrease(of: fewer, unit: unit)

            insights.append(decrease)
            goodPoint = decrease.fact
        }

        guard !insights.isEmpty else {
            return nil
        }

        let rows = memos
            .filter { $0.count >= 2 }
            .prefix(maximumRows)
            .map(\.row)

        let summary = Summary(
            focus: target.focus,
            rows: Array(rows),
            goodPoint: goodPoint,
            action: action
        )

        return ReviewBreakdown(insights: insights, summary: summary)
    }
}

public extension ReviewBreakdown.Focus {
    var hasPrevious: Bool {
        previousCount > 0
    }

    var hasSamePrice: Bool {
        let isSmall = abs(unitPrice - previousUnitPrice) * 100 < previousUnitPrice * 15
        return isSmall && abs(priceEffect) <= abs(countEffect)
    }

    var unitPrice: Int {
        count > 0 ? amount / count : 0
    }

    var previousUnitPrice: Int {
        hasPrevious ? previousAmount / previousCount : 0
    }

    var countEffect: Int {
        hasPrevious ? (count - previousCount) * previousUnitPrice : 0
    }

    var priceEffect: Int {
        hasPrevious ? amount - previousAmount - countEffect : 0
    }
}

public extension ReviewBreakdown.Action {
    var sentence: String {
        "\(lead)、\(ReviewInsight.yen(amount)) 浮きます。"
    }
}

extension ReviewBreakdown {
    struct Tally: Hashable {
        let name: String
        var count = 0
        var previousCount = 0
        var amount = 0
        var previousAmount = 0

        var unitPrice: Int {
            count > 0 ? amount / count : 0
        }

        var previousUnitPrice: Int {
            previousCount > 0 ? previousAmount / previousCount : 0
        }

        var row: Row {
            Row(
                name: name,
                count: count,
                previousCount: previousCount,
                amount: amount,
                previousAmount: previousAmount
            )
        }

        var focus: Focus {
            Focus(
                name: name,
                count: count,
                previousCount: previousCount,
                amount: amount,
                previousAmount: previousAmount
            )
        }
    }
}

private extension ReviewBreakdown {
    static func tallies(
        of input: Input,
        name: (Spend) -> String?
    ) -> [Tally] {
        var tallies: [String: Tally] = [:]

        for spend in input.current {
            guard let key = name(spend) else {
                continue
            }

            tallies[key, default: Tally(name: key)].count += 1
            tallies[key, default: Tally(name: key)].amount += spend.amount
        }

        for spend in input.previous {
            guard let key = name(spend) else {
                continue
            }

            tallies[key, default: Tally(name: key)].previousCount += 1
            tallies[key, default: Tally(name: key)].previousAmount += spend.amount
        }

        return tallies.values.sorted {
            $0.amount == $1.amount ? $0.name < $1.name : $0.amount > $1.amount
        }
    }

    static func isRising(
        _ tally: Tally,
        in input: Input
    ) -> Bool {
        input.hasPrevious && tally.previousCount > 0 && tally.amount > tally.previousAmount
    }

    static func memoTallies(of input: Input) -> [Tally] {
        tallies(of: input) { spend in
            spend.category == input.category ? normalized(spend.memo) : nil
        }
    }

    static func fewer(
        in tallies: [Tally],
        except name: String
    ) -> Tally? {
        tallies
            .filter { $0.name != name && $0.previousCount - $0.count >= 2 }
            .max { $0.previousCount - $0.count < $1.previousCount - $1.count }
    }
}
