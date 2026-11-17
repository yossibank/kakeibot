import Foundation

public struct ReviewInsight: Hashable, Sendable {
    public let kind: Kind
    public let weight: Int
    public let fact: String
    public let suggestions: [String]

    public init(
        kind: Kind,
        weight: Int,
        fact: String,
        suggestions: [String]
    ) {
        self.kind = kind
        self.weight = weight
        self.fact = fact
        self.suggestions = suggestions
    }
}

public extension ReviewInsight {
    enum Kind: String, Sendable {
        case overBudget
        case budgetPace
        case deficit
        case increase
        case largeExpense
        case decrease
        case withinBudget
        case surplus
        case total
    }

    struct Category: Hashable, Sendable {
        public let name: String
        public let amount: Int
        public let previous: Int
        public let budget: Int?

        public init(
            name: String,
            amount: Int,
            previous: Int,
            budget: Int?
        ) {
            self.name = name
            self.amount = amount
            self.previous = previous
            self.budget = budget
        }
    }

    struct Expense: Hashable, Sendable {
        public let categoryName: String
        public let amount: Int

        public init(
            categoryName: String,
            amount: Int
        ) {
            self.categoryName = categoryName
            self.amount = amount
        }
    }

    struct Input: Hashable, Sendable {
        public let scale: ReviewPeriod.Scale
        public let isCurrent: Bool
        public let elapsedDays: Int
        public let totalDays: Int
        public let expense: Int
        public let previousExpense: Int
        public let income: Int
        public let hasPrevious: Bool
        public let categories: [Category]
        public let largestExpense: Expense?

        public init(
            scale: ReviewPeriod.Scale,
            isCurrent: Bool,
            elapsedDays: Int,
            totalDays: Int,
            expense: Int,
            previousExpense: Int,
            income: Int,
            hasPrevious: Bool,
            categories: [Category],
            largestExpense: Expense?
        ) {
            self.scale = scale
            self.isCurrent = isCurrent
            self.elapsedDays = elapsedDays
            self.totalDays = totalDays
            self.expense = expense
            self.previousExpense = previousExpense
            self.income = income
            self.hasPrevious = hasPrevious
            self.categories = categories
            self.largestExpense = largestExpense
        }
    }

    var isGood: Bool {
        switch kind {
        case .decrease, .withinBudget, .surplus: true
        case .overBudget, .budgetPace, .deficit, .increase, .largeExpense, .total: false
        }
    }

    var labeledFact: String {
        let label = switch kind {
        case .decrease, .withinBudget, .surplus: "良い点"
        case .overBudget, .budgetPace, .deficit, .increase, .largeExpense: "気を付けたい点"
        case .total: "事実"
        }

        return "\(label)：\(fact)"
    }

    static func pick(from input: Input) -> [ReviewInsight] {
        let ranked = all(from: input).sorted { $0.weight > $1.weight }

        guard let first = ranked.first else {
            return [total(from: input)]
        }

        let rest = ranked.dropFirst()
        let good = first.isGood ? nil : rest.first(where: \.isGood)

        guard let second = good ?? rest.first else {
            return [first]
        }

        return [first, second]
    }

    static func yen(_ amount: Int) -> String {
        "\(amount.formatted(.number.locale(locale)))円"
    }
}

private extension ReviewInsight {
    static let locale = Locale(identifier: "ja_JP")

    static func all(from input: Input) -> [ReviewInsight] {
        var insights: [ReviewInsight] = []

        for category in input.categories {
            if let insight = budget(of: category, in: input) {
                insights.append(insight)
            }

            if input.hasPrevious,
               let insight = change(of: category, in: input) {
                insights.append(insight)
            }
        }

        if let insight = withinBudget(in: input) {
            insights.append(insight)
        }

        if let insight = balance(of: input) {
            insights.append(insight)
        }

        if let insight = largeExpense(in: input) {
            insights.append(insight)
        }

        return insights
    }

    static func budget(
        of category: Category,
        in input: Input
    ) -> ReviewInsight? {
        guard
            let budget = category.budget,
            budget > 0
        else {
            return nil
        }

        if category.amount > budget {
            let over = yen(category.amount - budget)
            let fact = "\(category.name)は、予算の \(yen(budget)) を \(over) 超えています。"

            let suggestions = overBudgetSuggestions(
                name: category.name,
                budget: yen(budget),
                over: over,
                wording: wording(of: input)
            )

            return ReviewInsight(
                kind: .overBudget,
                weight: 90,
                fact: fact,
                suggestions: suggestions
            )
        }

        guard
            input.isCurrent,
            input.totalDays > 0,
            input.elapsedDays < input.totalDays
        else {
            return nil
        }

        let elapsed = input.elapsedDays * 100 / input.totalDays
        let used = category.amount * 100 / budget

        guard
            used >= 50,
            used - elapsed >= 20
        else {
            return nil
        }

        let daysLeft = input.totalDays - input.elapsedDays
        let perDay = (budget - category.amount) / daysLeft
        let name = category.name
        let unit = input.scale.unitName
        let pace = "\(name)は、\(unit)の \(elapsed)% が過ぎたところで、予算の \(used)% を使っています。"
        let plan = "予算に収めるには、残りの \(daysLeft) 日を 1 日 \(yen(perDay)) にします。"
        let weight = 80 + used - elapsed

        let suggestions = budgetPaceSuggestions(
            name: name,
            daysLeft: daysLeft,
            perDay: yen(perDay)
        )

        return ReviewInsight(
            kind: .budgetPace,
            weight: weight,
            fact: pace + plan,
            suggestions: suggestions
        )
    }

    static func change(
        of category: Category,
        in input: Input
    ) -> ReviewInsight? {
        guard category.previous > 0 else {
            return nil
        }

        let difference = category.amount - category.previous
        let percent = abs(difference) * 100 / category.previous
        let name = category.name
        let unit = input.scale.unitName
        let from = yen(category.previous)
        let to = yen(category.amount)
        let words = wording(of: input)

        if difference >= 5000,
           percent >= 30 {
            let fact = "\(name)が、前の\(unit)の \(from) から \(to) に増えています（\(percent)% 増）。"
            let weight = 60 + min(difference / 1000, 20)

            let suggestions = increaseSuggestions(
                name: name,
                from: from,
                to: to,
                hasBudget: (category.budget ?? 0) > 0,
                wording: words
            )

            return ReviewInsight(
                kind: .increase,
                weight: weight,
                fact: fact,
                suggestions: suggestions
            )
        }

        if -difference >= 3000,
           percent >= 10 {
            let fact = "\(name)が、前の\(unit)の \(from) から \(to) に減っています（\(percent)% 減）。"
            let weight = 50 + min(-difference / 1000, 10)

            let suggestions = decreaseSuggestions(
                name: name,
                from: from,
                to: to,
                wording: words
            )

            return ReviewInsight(
                kind: .decrease,
                weight: weight,
                fact: fact,
                suggestions: suggestions
            )
        }

        return nil
    }

    static func withinBudget(in input: Input) -> ReviewInsight? {
        let budgeted = input.categories.filter { ($0.budget ?? 0) > 0 }

        guard
            input.isCurrent,
            input.totalDays > 0,
            !budgeted.isEmpty
        else {
            return nil
        }

        let elapsed = input.elapsedDays * 100 / input.totalDays

        let isOnPace = budgeted.allSatisfy { category in
            let budget = category.budget ?? 1
            return category.amount * 100 / budget <= elapsed
        }

        guard isOnPace else {
            return nil
        }

        let unit = input.scale.unitName
        let fact = "予算のあるカテゴリは、どれも\(unit)の \(elapsed)% のペースの内に収まっています。"

        return ReviewInsight(
            kind: .withinBudget,
            weight: 40,
            fact: fact,
            suggestions: withinBudgetSuggestions(unit: unit)
        )
    }

    static func balance(of input: Input) -> ReviewInsight? {
        guard input.income > 0 else {
            return nil
        }

        let balance = input.income - input.expense

        let income = yen(input.income)

        if balance < 0 {
            let over = yen(-balance)
            let fact = "収入の \(income) より、支出が \(over) 多くなっています。"

            let suggestions = deficitSuggestions(
                income: income,
                over: over,
                wording: wording(of: input)
            )

            return ReviewInsight(
                kind: .deficit,
                weight: 75,
                fact: fact,
                suggestions: suggestions
            )
        }

        guard
            !input.isCurrent,
            balance > 0
        else {
            return nil
        }

        let left = yen(balance)
        let fact = "収入の \(income) から、\(left) 残せました。"

        let suggestions = surplusSuggestions(
            left: left,
            unit: input.scale.unitName
        )

        return ReviewInsight(
            kind: .surplus,
            weight: 45,
            fact: fact,
            suggestions: suggestions
        )
    }

    static func largeExpense(in input: Input) -> ReviewInsight? {
        guard
            let expense = input.largestExpense,
            input.expense >= 10000,
            expense.amount >= 5000
        else {
            return nil
        }

        let percent = expense.amount * 100 / input.expense

        guard percent >= 20 else {
            return nil
        }

        let name = expense.categoryName
        let amount = yen(expense.amount)
        let fact = "\(name)の 1 回の出費 \(amount) が、支出の \(percent)% を占めています。"

        let suggestions = largeExpenseSuggestions(
            name: name,
            amount: amount,
            unit: input.scale.unitName
        )

        return ReviewInsight(
            kind: .largeExpense,
            weight: 55,
            fact: fact,
            suggestions: suggestions
        )
    }

    static func total(from input: Input) -> ReviewInsight {
        let total = "支出は \(yen(input.expense)) です。"
        let words = wording(of: input)

        guard input.hasPrevious else {
            return ReviewInsight(
                kind: .total,
                weight: 0,
                fact: total,
                suggestions: totalSuggestions(difference: nil, wording: words)
            )
        }

        let difference = input.expense - input.previousExpense
        let previous = "前の\(input.scale.unitName)"

        let change = switch difference {
        case 0: "\(previous)と同じです。"
        case 1...: "\(previous)より \(yen(difference)) 多いです。"
        default: "\(previous)より \(yen(-difference)) 少ないです。"
        }

        return ReviewInsight(
            kind: .total,
            weight: 0,
            fact: total + change,
            suggestions: totalSuggestions(difference: difference, wording: words)
        )
    }
}
