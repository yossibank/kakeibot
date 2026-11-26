import Core
import Store

@MainActor
public protocol SettingsFoldModel: ScreenPerforming {
    associatedtype Input

    var input: Input { get }

    func foldStore() -> SettingsFoldStore
}

public extension SettingsFoldModel {
    func loadFold(_ fold: KeyPath<Input, SettingsFoldInput>) async {
        let fold = input[keyPath: fold]
        let screens = try? await foldStore().database.setting(fold.key)
        fold.isClosed = screens?.contains(fold.screen) ?? false
    }

    @discardableResult
    func setFold(
        _ fold: KeyPath<Input, SettingsFoldInput>,
        closed isClosed: Bool
    ) -> Task<Void, Never> {
        let fold = input[keyPath: fold]
        let database = foldStore().database
        let key = fold.key
        let screen = fold.screen

        fold.isClosed = isClosed

        return Task {
            var screens = await (try? database.setting(key)) ?? []

            if isClosed {
                screens.insert(screen)
            } else {
                screens.remove(screen)
            }

            try? await database.setSetting(key, to: screens)
        }
    }
}
