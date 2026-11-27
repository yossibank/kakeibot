import Core

public extension AssetsModel {
    enum EntrySource: Equatable, Sendable {
        case moved(UpcomingBill)
        case unpaid([WalletRow])
    }

    enum Sheet: Equatable, Sendable {
        case reward
        case newGoal
        case newWallet(Wallet.Kind)
        case adjustment(WalletRow)
        case outlook
        case entries(EntrySource)
    }

    enum Opening: Equatable, Sendable {
        case entry(Entry.ID)
        case recurring(Recurring.ID)
    }

    struct GoalTarget: Hashable, Identifiable, Sendable {
        public let goal: RewardGoal?
    }

    enum RewardChild: Hashable, Sendable {
        case goal(GoalTarget)
        case rules
    }

    struct RewardSheet: Equatable, Sendable {
        public internal(set) var isGuideOpen = false
    }
}

public extension AssetsModel.GoalTarget {
    var id: RewardGoal.ID? {
        goal?.id
    }
}

public extension AssetsModel.Sheet {
    enum Key: Hashable, Sendable {
        case reward
        case newGoal
        case newWallet(Wallet.Kind)
        case adjustment(Wallet.ID)
        case outlook
        case moved(Recurring.ID)
        case unpaid
    }
}

public extension AssetsModel.State {
    var goalTarget: AssetsModel.GoalTarget? {
        presented.rewardChild.goal
    }

    var isEditingRules: Bool {
        presented.rewardChild.isShowing(.rules)
    }

    func present(_ sheet: AssetsModel.Sheet) {
        if sheet == .reward {
            presented.reward = AssetsModel.RewardSheet()
            presented.rewardChild.closeAll()
        }

        presented.sheet.show(sheet)
    }

    func editGoal(_ goal: RewardGoal?) {
        presented.rewardChild.show(.goal(AssetsModel.GoalTarget(goal: goal)))
    }

    func toggleGuide() {
        presented.reward.isGuideOpen.toggle()
    }

    func open(afterSheet opening: AssetsModel.Opening) {
        pending = opening
    }

    func takePending() -> AssetsModel.Opening? {
        guard let pending else {
            return nil
        }

        self.pending = nil

        return pending
    }
}

extension AssetsModel.Sheet: Identifiable {
    public var id: Key {
        switch self {
        case .reward: .reward
        case .newGoal: .newGoal
        case let .newWallet(kind): .newWallet(kind)
        case let .adjustment(row): .adjustment(row.id)
        case .outlook: .outlook
        case let .entries(.moved(bill)): .moved(bill.id)
        case .entries(.unpaid): .unpaid
        }
    }
}

public extension Shown<AssetsModel.RewardChild> {
    var goal: AssetsModel.GoalTarget? {
        get {
            guard case let .goal(target) = current else {
                return nil
            }

            return target
        }
        set {
            if let newValue {
                show(.goal(newValue))
            } else if goal != nil {
                closeAll()
            }
        }
    }
}
