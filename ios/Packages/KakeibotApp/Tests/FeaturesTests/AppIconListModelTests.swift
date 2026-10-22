import Features
import Testing

@MainActor
struct AppIconListModelTests {
    @Test
    func startsFromCurrentIcon() {
        let switcher = Switcher(name: "AppIcon-Forest")

        let model = AppIconListModel(switcher: switcher.client)

        #expect(model.current == .forest)
    }

    @Test
    func switchesToChosenIcon() async {
        let switcher = Switcher(name: nil)
        let model = AppIconListModel(switcher: switcher.client)

        await model.select(.gold)
        let gold = switcher.name

        await model.select(.white)

        #expect(gold == "AppIcon-Gold")
        #expect(switcher.name == nil)
        #expect(model.current == .white)
    }

    @Test
    func keepsIconWhenSwitchFails() async {
        let switcher = Switcher(name: nil, fails: true)
        let model = AppIconListModel(switcher: switcher.client)

        await model.select(.black)

        #expect(model.current == .white)
        #expect(model.errorNotice.message == "アイコンを変えられませんでした")
    }
}

extension AppIconListModelTests {
    @MainActor
    final class Switcher {
        var name: String?
        let fails: Bool

        var client: AppIconSwitcher {
            AppIconSwitcher {
                self.name
            } setName: { name in
                if self.fails {
                    throw SwitchError.failed
                }

                self.name = name
            }
        }

        init(
            name: String?,
            fails: Bool = false
        ) {
            self.name = name
            self.fails = fails
        }
    }

    enum SwitchError: Error {
        case failed
    }
}
