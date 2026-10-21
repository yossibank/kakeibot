import DesignSystem
import Observation

@MainActor
@Observable
public final class AppIconListModel {
    public private(set) var current: AppIconChoice

    public internal(set) var errorNotice = ErrorNotice()

    private let switcher: AppIconSwitcher

    public init(switcher: AppIconSwitcher = .live) {
        self.switcher = switcher
        self.current = AppIconChoice(alternateName: switcher.currentName())
    }
}

public extension AppIconListModel {
    func select(_ choice: AppIconChoice) async {
        guard choice != current else {
            return
        }

        let previous = current
        current = choice

        do {
            try await switcher.setName(choice.alternateName)
        } catch {
            current = previous
            errorNotice.show(Self.changeFailedMessage)
        }
    }
}

private extension AppIconListModel {
    static let changeFailedMessage = "アイコンを変えられませんでした"
}
