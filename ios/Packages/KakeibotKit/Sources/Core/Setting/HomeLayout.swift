public struct HomeLayout: Hashable, Sendable {
    public private(set) var order: [HomeSection]
    public private(set) var hidden: Set<HomeSection>

    public init(
        order: [HomeSection] = HomeSection.standard,
        hidden: Set<HomeSection> = []
    ) {
        var seen = Set<HomeSection>()
        let listed = order.filter { seen.insert($0).inserted }
        let missing = HomeSection.allCases.filter { !seen.contains($0) }
        let order = listed + missing
        let added = missing.filter { !HomeSection.standard.contains($0) }
        let hidden = hidden.union(added)

        self.order = order
        self.hidden = hidden.count < order.count ? hidden : hidden.subtracting(order.prefix(1))
    }
}

public extension HomeLayout {
    enum Slot: Hashable, Sendable {
        case section(HomeSection)
        case boundary

        public var section: HomeSection? {
            guard case let .section(section) = self else {
                return nil
            }

            return section
        }
    }

    static let standard = Self()

    var visible: [HomeSection] {
        order.filter { !hidden.contains($0) }
    }

    var slots: [Slot] {
        let shown = visible.map(Slot.section)
        let hiddenSlots = order.filter(isHidden).map(Slot.section)

        return shown + [.boundary] + hiddenSlots
    }

    func isHidden(_ section: HomeSection) -> Bool {
        hidden.contains(section)
    }

    func canHide(_ section: HomeSection) -> Bool {
        isHidden(section) || visible.count > 1
    }

    mutating func move(
        _ section: HomeSection,
        toSlot index: Int
    ) {
        var slots = slots

        guard let from = slots.firstIndex(of: .section(section)) else {
            return
        }

        slots.remove(at: from)
        slots.insert(.section(section), at: min(max(index, 0), slots.count))

        guard
            let boundary = slots.firstIndex(of: .boundary),
            boundary > 0
        else {
            return
        }

        let shown = slots[..<boundary].compactMap(\.section)
        let hiddenSections = slots[(boundary + 1)...].compactMap(\.section)

        order = shown + hiddenSections
        hidden = Set(hiddenSections)
    }

    mutating func setHidden(
        _ section: HomeSection,
        _ isHidden: Bool
    ) {
        guard isHidden else {
            hidden.remove(section)
            return
        }

        guard canHide(section) else {
            return
        }

        hidden.insert(section)
    }
}
