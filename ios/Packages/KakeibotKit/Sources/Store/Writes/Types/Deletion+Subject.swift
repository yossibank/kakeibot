import Core

public extension Deletion {
    struct Subject: Equatable, Sendable {
        public let kind: Kind
        public let count: Int
        public let names: [String]
    }

    enum Kind: Sendable {
        case wallet
        case category
        case recurring
        case template
        case rewardRule
        case theme
        case shelfIcon
        case valuation
        case adjustment
    }

    var subject: Subject? {
        if !wallets.isEmpty {
            return Subject(.wallet, names: wallets.map(\.name))
        }

        if !categories.isEmpty {
            return Subject(.category, names: categories.map(\.name))
        }

        if !recurrings.isEmpty {
            return Subject(.recurring, names: recurrings.map(\.memo))
        }

        if !templates.isEmpty {
            return Subject(.template, names: templates.map(\.name))
        }

        if !rewardRules.isEmpty {
            return Subject(.rewardRule, names: rewardRules.map(\.name))
        }

        if !themes.isEmpty {
            return Subject(.theme, names: themes.map(\.name))
        }

        if !shelfIcons.isEmpty {
            return Subject(.shelfIcon, names: shelfIcons.map { _ in nil })
        }

        if !valuations.isEmpty {
            return Subject(.valuation, names: valuations.map { _ in nil })
        }

        if !adjustments.isEmpty {
            return Subject(.adjustment, names: adjustments.map { _ in nil })
        }

        return nil
    }
}

private extension Deletion.Subject {
    init(
        _ kind: Deletion.Kind,
        names: [String?]
    ) {
        self.kind = kind
        self.count = names.count
        self.names = names.compactMap { name in
            name.flatMap { $0.isEmpty ? nil : $0 }
        }
    }
}
