import Core

public extension ThemeListModel {
    enum Offer: Hashable, Sendable {
        case create(base: ThemePalette?)
        case select(ThemeChoice)
    }

    enum EditTarget: Hashable, Identifiable, Sendable {
        case new(base: ThemePalette?)
        case edit(Theme)
    }

    enum Overlay: Hashable, Sendable {
        case menu(ThemeChoice)
        case editing(EditTarget)
        case offer(Offer)
    }

    struct Presented: ScreenEditable {
        public var overlay = Shown<Overlay>()
    }
}

public extension ThemeListModel {
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
        guard let offer = state.presented.overlay.current?.offer else {
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

public extension ThemeListModel.Overlay {
    var menu: ThemeChoice? {
        guard case let .menu(choice) = self else {
            return nil
        }

        return choice
    }

    var editing: ThemeListModel.EditTarget? {
        guard case let .editing(target) = self else {
            return nil
        }

        return target
    }

    var offer: ThemeListModel.Offer? {
        guard case let .offer(offer) = self else {
            return nil
        }

        return offer
    }
}

public extension ThemeListModel.EditTarget {
    var id: String {
        switch self {
        case .new: "new"
        case let .edit(theme): theme.id.description
        }
    }

    var theme: Theme? {
        switch self {
        case .new: nil
        case let .edit(theme): theme
        }
    }

    var base: ThemePalette? {
        switch self {
        case let .new(base): base
        case .edit: nil
        }
    }
}

public extension ThemeListModel.Offer {
    var feature: String {
        switch self {
        case .create: "テーマを作るの"
        case .select: "作ったテーマ"
        }
    }
}

public extension ThemeListModel.State {
    func press(_ choice: ThemeChoice?) {
        if pressing != choice {
            pressing = choice
        }
    }

    func present(_ overlay: ThemeListModel.Overlay) {
        if presented.overlay.current != overlay {
            presented.overlay.show(overlay)
        }
    }

    func close(_ overlay: ThemeListModel.Overlay?) {
        if let overlay,
           presented.overlay.current == overlay {
            presented.overlay.closeAll()
        }
    }
}
