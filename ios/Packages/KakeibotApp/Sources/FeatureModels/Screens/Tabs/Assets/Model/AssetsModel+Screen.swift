import Core

public extension AssetsModel {
    enum EntrySource: Equatable, Sendable {
        case moved(UpcomingBill)
        case unpaid([WalletRow])
    }

    enum Sheet: Equatable {
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

    struct GoalTarget: Equatable, Identifiable {
        public let goal: RewardGoal?
    }

    enum RewardChild: Equatable {
        case goal(GoalTarget)
        case rules
    }

    struct RewardSheet: Equatable {
        public internal(set) var isGuideOpen = false
        public internal(set) var child: RewardChild?
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
        get {
            guard case let .goal(target) = reward.child else {
                return nil
            }

            return target
        }
        set {
            if let newValue {
                reward.child = .goal(newValue)
            } else if goalTarget != nil {
                reward.child = nil
            }
        }
    }

    var isEditingRules: Bool {
        get {
            reward.child == .rules
        }
        set {
            if newValue {
                reward.child = .rules
            } else if isEditingRules {
                reward.child = nil
            }
        }
    }

    func present(_ sheet: AssetsModel.Sheet) {
        if sheet == .reward {
            reward = AssetsModel.RewardSheet()
        }

        self.sheet = sheet
    }

    func editGoal(_ goal: RewardGoal?) {
        reward.child = .goal(AssetsModel.GoalTarget(goal: goal))
    }

    func toggleGuide() {
        reward.isGuideOpen.toggle()
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
