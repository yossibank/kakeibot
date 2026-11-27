public extension MainModel {
    struct TabSelection: Equatable, Sendable {
        public private(set) var current: Tab = .home
        public private(set) var visited: Set<Tab> = [.home]

        public init() {}
    }
}

public extension MainModel.TabSelection {
    mutating func select(_ tab: MainModel.Tab) {
        current = tab
        visited.insert(tab)
    }
}
