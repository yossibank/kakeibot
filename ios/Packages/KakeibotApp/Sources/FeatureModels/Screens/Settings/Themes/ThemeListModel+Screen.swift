import Core

public extension ThemeListModel {
    enum Offer: Hashable {
        case create(base: ThemePalette?)
        case select(ThemeChoice)

        public var feature: String {
            switch self {
            case .create: "テーマを作るの"
            case .select: "作ったテーマ"
            }
        }
    }

    enum EditTarget: Hashable, Identifiable {
        case new(base: ThemePalette?)
        case edit(Theme)

        public var id: String {
            switch self {
            case .new: "new"
            case let .edit(theme): theme.id.description
            }
        }

        public var theme: Theme? {
            switch self {
            case .new: nil
            case let .edit(theme): theme
            }
        }

        public var base: ThemePalette? {
            switch self {
            case let .new(base): base
            case .edit: nil
            }
        }
    }

    enum Presented: Hashable {
        case menu(ThemeChoice)
        case editing(EditTarget)
        case offer(Offer)

        public var menu: ThemeChoice? {
            guard case let .menu(choice) = self else {
                return nil
            }

            return choice
        }

        public var editing: EditTarget? {
            guard case let .editing(target) = self else {
                return nil
            }

            return target
        }

        public var offer: Offer? {
            guard case let .offer(offer) = self else {
                return nil
            }

            return offer
        }
    }

    func choose(
        _ choice: ThemeChoice,
        isPro: Bool
    ) async {
        if case .custom = choice,
           choice != input.current,
           !isPro {
            state.present(.offer(.select(choice)))
            return
        }

        await select(choice)
    }

    func create(
        base: ThemePalette?,
        isPro: Bool
    ) {
        state.present(isPro ? .editing(.new(base: base)) : .offer(.create(base: base)))
    }

    func unlock() async {
        guard let offer = state.presented?.offer else {
            return
        }

        switch offer {
        case let .create(base):
            state.present(.editing(.new(base: base)))

        case let .select(choice):
            state.close(.offer(offer))

            await select(choice)
        }
    }
}

public extension ThemeListModel.State {
    func press(_ choice: ThemeChoice?) {
        if pressing != choice {
            pressing = choice
        }
    }

    func present(_ presented: ThemeListModel.Presented) {
        if self.presented != presented {
            self.presented = presented
        }
    }

    func close(_ presented: ThemeListModel.Presented?) {
        if self.presented == presented,
           presented != nil {
            self.presented = nil
        }
    }
}
