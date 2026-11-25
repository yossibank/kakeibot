import Core

public extension RecordsModel {
    enum BatchTarget: Hashable, Identifiable, Sendable {
        case category(Entry.Kind)
        case wallet

        public var id: Self {
            self
        }
    }

    enum FilterTab: Hashable, Sendable {
        case expense
        case income
        case wallet
        case tag
    }

    enum Presented: Equatable, Identifiable {
        case markMenu(LocalDate)
        case stamp(LocalDate)
        case reward(LocalDate)
        case batch(BatchTarget)
        case filter
        case adjustment(AdjustmentRow)

        public var id: Key {
            switch self {
            case let .markMenu(date): .markMenu(date)
            case let .stamp(date): .stamp(date)
            case let .reward(date): .reward(date)
            case let .batch(target): .batch(target)
            case .filter: .filter
            case let .adjustment(row): .adjustment(row.id)
            }
        }

        public var isSheet: Bool {
            switch self {
            case .markMenu: false
            case .stamp, .reward, .batch, .filter, .adjustment: true
            }
        }
    }

    struct Screen {
        public var isAddingMark = false
        public var filterTab: FilterTab = .expense
        public var clearedSearches: [String]?

        public internal(set) var presented: Presented?
        public internal(set) var selection: Set<Entry.ID>?
        public internal(set) var openItemIds: Set<Entry.ID> = []
        public internal(set) var isMovingForward = true
    }
}

public extension RecordsModel.Presented {
    enum Key: Hashable, Sendable {
        case markMenu(LocalDate)
        case stamp(LocalDate)
        case reward(LocalDate)
        case batch(RecordsModel.BatchTarget)
        case filter
        case adjustment(Adjustment.ID)
    }
}

public extension RecordsModel.State {
    var markMenuDate: LocalDate? {
        guard case let .markMenu(date) = screen.presented else {
            return nil
        }

        return date
    }

    var sheet: RecordsModel.Presented? {
        get {
            screen.presented?.isSheet == true ? screen.presented : nil
        }
        set {
            if let newValue {
                present(newValue)
            } else if screen.presented?.isSheet == true {
                screen.presented = nil
            }
        }
    }

    func present(_ presented: RecordsModel.Presented) {
        screen.isAddingMark = false

        if presented == .filter {
            screen.filterTab = .expense
        }

        screen.presented = presented
    }

    func finishAddingMark() {
        if screen.isAddingMark {
            screen.isAddingMark = false
        }
    }

    func closeMarkMenu() {
        if markMenuDate != nil {
            screen.presented = nil
        }
    }

    func select(_ ids: Set<Entry.ID>) {
        if screen.selection != ids {
            screen.selection = ids
        }
    }

    func finishSelecting() {
        if screen.selection != nil {
            screen.selection = nil
        }
    }

    func toggleItems(of id: Entry.ID) {
        if screen.openItemIds.contains(id) {
            screen.openItemIds.remove(id)
        } else {
            screen.openItemIds.insert(id)
        }
    }

    func head(forward isForward: Bool) {
        if screen.isMovingForward != isForward {
            screen.isMovingForward = isForward
        }
    }
}
