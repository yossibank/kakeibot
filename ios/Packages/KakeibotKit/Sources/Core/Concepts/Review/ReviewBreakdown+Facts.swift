extension ReviewBreakdown {
    static func change(
        of tally: Tally,
        unit: String
    ) -> String? {
        let name = tally.name
        let from = tally.previousCount
        let to = tally.count
        let price = ReviewInsight.yen(tally.unitPrice)
        let previousPrice = ReviewInsight.yen(tally.previousUnitPrice)
        let isCountUp = to > from
        let isSame = tally.focus.hasSamePrice
        let isPriceUp = !isSame && tally.unitPrice > tally.previousUnitPrice

        switch (isCountUp, isPriceUp) {
        case (true, true):
            return "\(name)が、前の\(unit)の \(from) 回から \(to) 回に増え、"
                + "1 回もおよそ \(previousPrice) から \(price) に上がっています。"

        case (true, false):
            let same = isSame ? "1 回はおよそ \(price) で、前の\(unit)と変わりません。" : ""
            return "\(name)が、前の\(unit)の \(from) 回から \(to) 回に増えています。" + same

        case (false, true):
            return "\(name)の 1 回が、前の\(unit)のおよそ \(previousPrice) から \(price) に上がっています。"
                + "回数は \(to) 回です。"

        case (false, false):
            return nil
        }
    }

    static func reason(
        in memos: [Tally],
        for category: Tally
    ) -> ReviewInsight? {
        let increase = category.amount - category.previousAmount

        let top = memos
            .filter { $0.count >= 2 }
            .max { $0.amount - $0.previousAmount < $1.amount - $1.previousAmount }

        guard
            let top,
            (top.amount - top.previousAmount) * 2 >= increase
        else {
            return nil
        }

        let amount = ReviewInsight.yen(top.amount - top.previousAmount)
        let fact = "\(category.name)の増えた分のうち、\(top.name)が \(amount) を占めています。"

        return ReviewInsight(
            kind: .increase,
            weight: 0,
            fact: fact,
            suggestions: []
        )
    }

    static func pace(of tally: Tally) -> ReviewInsight {
        let price = ReviewInsight.yen(tally.unitPrice)
        let fact = "\(tally.name)は \(tally.count) 回で、1 回はおよそ \(price) です。"

        return ReviewInsight(
            kind: .total,
            weight: 0,
            fact: fact,
            suggestions: []
        )
    }

    static func decrease(
        of tally: Tally,
        unit: String
    ) -> ReviewInsight {
        let fact = "\(tally.name)は、前の\(unit)の \(tally.previousCount) 回から \(tally.count) 回に減っています。"

        return ReviewInsight(
            kind: .decrease,
            weight: 0,
            fact: fact,
            suggestions: []
        )
    }

    static func saving(
        of tally: Tally,
        unit: String,
        isCurrent: Bool
    ) -> Action? {
        let name = tally.name

        if tally.count > tally.previousCount {
            let saved = (tally.count - tally.previousCount) * tally.unitPrice / 100 * 100
            let times = tally.previousCount

            guard saved >= 100 else {
                return nil
            }

            let lead = isCurrent
                ? "\(name)を前の\(unit)と同じ \(times) 回ほどに戻すと"
                : "次の\(unit)は、\(name)を \(times) 回ほどにすると"

            return Action(lead: lead, amount: saved)
        }

        let saved = (tally.unitPrice - tally.previousUnitPrice) * tally.count / 100 * 100
        let price = ReviewInsight.yen(tally.previousUnitPrice)

        guard saved >= 100 else {
            return nil
        }

        let lead = isCurrent
            ? "\(name)の 1 回を前の\(unit)の \(price) ほどに戻すと"
            : "次の\(unit)は、\(name)の 1 回を \(price) ほどにすると"

        return Action(lead: lead, amount: saved)
    }
}
