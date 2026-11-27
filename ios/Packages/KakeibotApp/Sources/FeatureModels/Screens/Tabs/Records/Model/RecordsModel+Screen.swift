import Core

public extension RecordsModel {
    enum BatchTarget: Hashable, Identifiable, Sendable {
        case category(Entry.Kind)
        case wallet
    }

    enum FilterTab: Hashable, Sendable {
        case expense
        case income
        case wallet
        case tag
    }

    enum Prompt: Hashable, Sendable {
        case delete
    }

    enum Presented: Equatable, Identifiable, Sendable {
        case markMenu(LocalDate)
        case stamp(LocalDate)
        case reward(LocalDate)
        case batch(BatchTarget)
        case filter
        case adjustment(AdjustmentRow)
    }

    struct Screen {
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

public extension RecordsModel.Presented {
    var id: Key {
        switch self {
        case let .markMenu(date): .markMenu(date)
        case let .stamp(date): .stamp(date)
        case let .reward(date): .reward(date)
        case let .batch(target): .batch(target)
        case .filter: .filter
        case let .adjustment(row): .adjustment(row.id)
        }
    }

    var isSheet: Bool {
        switch self {
        case .markMenu: false
        case .stamp, .reward, .batch, .filter, .adjustment: true
        }
    }
}

public extension RecordsModel.BatchTarget {
    var id: Self {
        self
    }
}

public extension RecordsModel.State {
    var markMenuDate: LocalDate? {
        guard case let .markMenu(date) = presented.current else {
            return nil
        }

        return date
    }

    var sheet: RecordsModel.Presented? {
        presented.sheet
    }

    func present(_ presented: RecordsModel.Presented) {
        fields.isAddingMark = false

        if presented == .filter {
            fields.filterTab = .expense
        }

        self.presented.show(presented)
    }

    func finishAddingMark() {
        if fields.isAddingMark {
            fields.isAddingMark = false
        }
    }

    func closeMarkMenu() {
        if markMenuDate != nil {
            presented.closeAll()
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

public extension Shown<RecordsModel.Presented> {
    var sheet: Value? {
        get {
            current?.isSheet == true ? current : nil
        }
        set {
            if let newValue {
                show(newValue)
            } else if current?.isSheet == true {
                closeAll()
            }
        }
    }
}
