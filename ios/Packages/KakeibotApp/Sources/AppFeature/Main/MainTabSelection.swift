import Observation

@MainActor
@Observable
final class MainTabSelection {
    var value: MainView.MainTab = .home {
        didSet {
            visited.insert(value)
        }
    }

    private(set) var visited: Set<MainView.MainTab> = [.home]
}
