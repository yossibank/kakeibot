import Foundation

public extension ReviewInsight {
    func suggestion(in period: ReviewPeriod) -> String {
        guard !suggestions.isEmpty else {
            return ""
        }

        let index = abs(period.sequence) % suggestions.count
        return suggestions[index]
    }
}

extension ReviewInsight {
    struct Wording {
        let unit: String
        let lead: String
        let keep: String
    }

    static func wording(of input: Input) -> Wording {
        let unit = input.scale.unitName

        return Wording(
            unit: unit,
            lead: input.isCurrent ? "残りの日は" : "次の\(unit)は",
            keep: input.isCurrent ? "残りの日も" : "次の\(unit)も"
        )
    }

    static func budgetPaceSuggestions(
        name: String,
        daysLeft: Int,
        perDay: String
    ) -> [String] {
        [
            "\(name)は、残りの \(daysLeft) 日を 1 日 \(perDay) にすると、予算に収まります。",
            "残りの \(daysLeft) 日は、\(name)を 1 日 \(perDay) までにすると予算の内です。",
            "\(name)の残りは 1 日 \(perDay) です。買う前に一度確かめてみましょう。",
            "\(name)は、使う前に残りを確かめると、1 日 \(perDay) に収めやすくなります。",
            "残りの \(daysLeft) 日で\(name)に使えるのは、1 日 \(perDay) です。途中で一度確かめてみましょう。"
        ]
    }

    static func overBudgetSuggestions(
        name: String,
        budget: String,
        over: String,
        wording: Wording
    ) -> [String] {
        let unit = wording.unit

        return [
            "\(wording.lead)、\(name)をこまめに確かめてみましょう。",
            "\(name)の予算 \(budget) が合っているか、次の\(unit)の初めに見直してみましょう。",
            "超えた \(over) がどの記録から来たか、\(name)の内訳で確かめてみましょう。",
            "次の\(unit)は、\(name)の残りが予算の半分を切ったところで確かめてみましょう。",
            "次の\(unit)は、\(name)の予算を先に取り分けてから使ってみましょう。"
        ]
    }

    static func deficitSuggestions(
        income: String,
        over: String,
        wording: Wording
    ) -> [String] {
        [
            "次の\(wording.unit)は、収入の \(income) を上限に予算を置いてみましょう。",
            "収入を超えた \(over) の中身を、内訳で確かめてみましょう。",
            "\(wording.lead)、大きな出費の予定を先に書き出してみましょう。",
            "決まって出ていく支出から、見直せるものを 1 つ探してみましょう。",
            "\(wording.lead)、途中で一度、収入と支出の差を確かめてみましょう。"
        ]
    }

    static func increaseSuggestions(
        name: String,
        from: String,
        to: String,
        hasBudget: Bool,
        wording: Wording
    ) -> [String] {
        let first = hasBudget
            ? "\(wording.lead)、\(name)の予算の残りを途中で確かめてみましょう。"
            : "\(name)に予算を置くと、使い過ぎに早く気付けます。"

        return [
            first,
            "\(name)が \(from) から \(to) に増えた理由を、記録で確かめてみましょう。",
            "次の\(wording.unit)は、\(name)を \(to) より少し下に抑えてみましょう。",
            "\(name)の記録にメモを残すと、次に増えた時に理由が分かります。",
            "\(name)のうち、続けて出ていくものが無いか確かめてみましょう。"
        ]
    }

    static func largeExpenseSuggestions(
        name: String,
        amount: String,
        unit: String
    ) -> [String] {
        [
            "\(name)の \(amount) のような出費は、毎月少しずつ取り分けておくと楽になります。",
            "\(name)のような大きな出費は、分かった時点で予定に入れておくと慌てません。",
            "\(amount) の出費を除くと、ふだんのペースが見えてきます。内訳で確かめてみましょう。",
            "次に\(name)で大きく使う時期の目安を、メモに残してみましょう。",
            "大きな出費があった\(unit)は、ほかのカテゴリを少し控えめにすると整います。"
        ]
    }

    static func decreaseSuggestions(
        name: String,
        from: String,
        to: String,
        wording: Wording
    ) -> [String] {
        [
            "\(name)が減ったやり方を、\(wording.keep)続けてみましょう。",
            "\(name)は \(from) から \(to) に下がりました。何を変えたか、メモに残してみましょう。",
            "\(name)で浮いた分を、次の\(wording.unit)の予算に回してみましょう。",
            "\(name)の減り方が続くか、\(wording.keep)確かめてみましょう。",
            "\(name)で続けられた工夫を、ほかのカテゴリでも試してみましょう。"
        ]
    }

    static func withinBudgetSuggestions(unit: String) -> [String] {
        [
            "このペースのまま、\(unit)の終わりまで続けてみましょう。",
            "予算の内に収まっています。残りの日も、今のペースで記録を続けてみましょう。",
            "予算の内に収まっているカテゴリの使い方を、ほかのカテゴリにも当ててみましょう。",
            "残りの日は、予算の残りが少ないカテゴリから先に確かめてみましょう。",
            "今のペースなら、\(unit)の終わりに予算が残りそうです。残りの行き先を決めておきましょう。"
        ]
    }

    static func surplusSuggestions(
        left: String,
        unit: String
    ) -> [String] {
        [
            "残せた \(left) の行き先を、次の\(unit)の初めに決めてみましょう。",
            "\(left) のうち、先に取り分ける額を決めておくと、次の\(unit)も残しやすくなります。",
            "残せたやり方を、次の\(unit)も続けてみましょう。",
            "次の\(unit)は、残したい額を先に決めてから予算を置いてみましょう。",
            "残せた\(unit)の内訳を、次の\(unit)の目安にしてみましょう。"
        ]
    }

    static func totalSuggestions(
        difference: Int?,
        wording: Wording
    ) -> [String] {
        let budget = "\(wording.lead)、大きいカテゴリに予算を 1 つ置いてみましょう。"
        let keep = "記録が続いています。\(wording.keep)同じように付けてみましょう。"

        guard let difference else {
            return [
                "内訳でいちばん大きいカテゴリを確かめてみましょう。",
                budget,
                "内訳の上位 3 つのカテゴリを確かめてみましょう。",
                keep
            ]
        }

        let previous = "前の\(wording.unit)"
        let direction = difference < 0 ? "減った" : "増えた"

        let gap = difference == 0
            ? "\(previous)と同じでも、内訳が変わっていないか確かめてみましょう。"
            : "\(previous)との差 \(yen(abs(difference))) が、どのカテゴリから来たか確かめてみましょう。"

        return [
            "内訳で、\(previous)より\(direction)カテゴリを確かめてみましょう。",
            gap,
            budget,
            "内訳の上位 3 つのカテゴリを、\(previous)と比べてみましょう。",
            keep
        ]
    }
}

private extension ReviewPeriod {
    var sequence: Int {
        let start = range.lowerBound

        return switch scale {
        case .week: start.dayNumber / 7
        case .month: start.year * 12 + start.month
        case .year: start.year
        }
    }
}
