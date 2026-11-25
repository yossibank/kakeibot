import DesignSystem
import Observation

@MainActor
@Observable
public final class AppIconListModel: ScreenPerforming {
    public let state = NoticeState()
    public let input: Input

    let dependencies: Dependencies

    public init(switcher: AppIconSwitcher = .live) {
        let name = switcher.currentName()

        self.input = Input(current: AppIconChoice(alternateName: name))
        self.dependencies = Dependencies(switcher: switcher)
    }
}

public extension AppIconListModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var current: AppIconChoice

        init(current: AppIconChoice) {
            self.current = current
        }
    }

    func select(_ choice: AppIconChoice) async {
        guard choice != input.current else {
            return
        }

        let previous = input.current

        input.current = choice

        do {
            try await dependencies.switcher.setName(choice.alternateName)
        } catch {
            input.current = previous
            state.errorNotice.show(Self.changeFailedMessage)
        }
    }
}

extension AppIconListModel {
    struct Dependencies {
        let switcher: AppIconSwitcher
    }
}

private extension AppIconListModel {
    static let changeFailedMessage = "アイコンを変えられませんでした"
}
