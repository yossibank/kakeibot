import Core

struct ReviewGoalItem: Identifiable {
    let goal: ReviewGoal
    let name: String
    let categoryName: String
    let progress: ReviewGoal.Progress

    var id: ReviewGoal.ID {
        goal.id
    }

    func title(unit: String) -> String {
        ReviewEmphasisText.plain(titleParts(unit: unit))
    }

    func titleParts(unit: String) -> [ReviewEmphasisText.Part] {
        switch goal.kind {
        case .count:
            [
                .name(name),
                .plain("を、\(unit) "),
                .number("\(goal.target)"),
                .plain(" 回までに")
            ]

        case .average:
            [
                .name(name),
                .plain("の 1 回を、"),
                .number(ReviewYen.number(goal.target)),
                .plain("円 までに")
            ]
        }
    }

    func value(_ number: Int) -> String {
        switch goal.kind {
        case .count: "\(number) 回"
        case .average: ReviewYen.text(number)
        }
    }
}
