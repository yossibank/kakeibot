public struct HomeLayout: Hashable, Sendable {
    public private(set) var order: [HomeSection]
    public private(set) var hidden: Set<HomeSection>

    public init(
        order: [HomeSection] = HomeSection.allCases,
        hidden: Set<HomeSection> = []
    ) {
        var seen = Set<HomeSection>()
        let listed = order.filter { seen.insert($0).inserted }
        let missing = HomeSection.allCases.filter { !seen.contains($0) }
        let order = listed + missing

        self.order = order
        self.hidden = hidden.count < order.count ? hidden : hidden.subtracting(order.prefix(1))
    }
}

public extension HomeLayout {
    static let standard = Self()

    var visible: [HomeSection] {
        order.filter { !hidden.contains($0) }
    }

    func isHidden(_ section: HomeSection) -> Bool {
        hidden.contains(section)
    }

    func canHide(_ section: HomeSection) -> Bool {
        isHidden(section) || visible.count > 1
    }

    mutating func move(
        _ section: HomeSection,
        to index: Int
    ) {
        guard let from = order.firstIndex(of: section) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        order.remove(at: from)
        order.insert(section, at: to)
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
