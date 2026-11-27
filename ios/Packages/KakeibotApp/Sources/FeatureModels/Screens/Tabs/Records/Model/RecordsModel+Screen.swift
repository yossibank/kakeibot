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

    enum Adding: Hashable, Sendable {
        case mark
    }

    enum Panel: Equatable, Identifiable, Sendable {
        case markMenu(LocalDate)
        case stamp(LocalDate)
        case reward(LocalDate)
        case batch(BatchTarget)
        case filter
        case adjustment(AdjustmentRow)
    }
}

public extension RecordsModel.Panel {
    enum Key: Hashable, Sendable {
        case markMenu(LocalDate)
        case stamp(LocalDate)
        case reward(LocalDate)
        case batch(RecordsModel.BatchTarget)
        case filter
        case adjustment(Adjustment.ID)
    }
}

public extension RecordsModel.Panel {
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
        guard case let .markMenu(date) = presented.panel.current else {
            return nil
        }

        return date
    }

    var sheet: RecordsModel.Panel? {
        presented.panel.sheet
    }

    func present(_ panel: RecordsModel.Panel) {
        presented.adding.closeAll()

        if panel == .filter {
            fields.filterTab = .expense
        }

        presented.panel.show(panel)
    }

    func finishAddingMark() {
        if presented.adding.isShowing(.mark) {
            presented.adding.close(.mark)
        }
    }

    func closeMarkMenu() {
        if markMenuDate != nil {
            presented.panel.closeAll()
        }
    }

    func select(_ ids: Set<Entry.ID>) {
        if fields.selection != ids {
            fields.selection = ids
        }
    }

    func finishSelecting() {
        if fields.selection != nil {
            fields.selection = nil
        }
    }

    func toggleItems(of id: Entry.ID) {
        if presented.openItemIds.contains(id) {
            presented.openItemIds.remove(id)
        } else {
            presented.openItemIds.insert(id)
        }
    }

    func head(forward isForward: Bool) {
        if isMovingForward != isForward {
            isMovingForward = isForward
        }
    }
}

public extension Shown<RecordsModel.Panel> {
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
