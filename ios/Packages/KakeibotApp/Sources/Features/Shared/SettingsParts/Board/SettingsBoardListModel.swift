@MainActor
protocol SettingsBoardListModel: SettingsBoardModel, ScreenModel {
    associatedtype Snapshot
    associatedtype Updates: AsyncSequence where Updates.Element == Snapshot

    var snapshot: Snapshot? { get set }

    func read() async throws -> Snapshot
    func updates() -> Updates
    func observe() async
    func items(in snapshot: Snapshot) -> [Item]
    func isHidden(_ item: Item) -> Bool
}

extension SettingsBoardListModel {
    var visible: [Item] {
        items(isHidden: false)
    }

    var hidden: [Item] {
        items(isHidden: true)
    }

    func load() async {
        do {
            snapshot = try await read()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observe(updates(), into: \.snapshot)
    }
}

private extension SettingsBoardListModel {
    func items(isHidden hidden: Bool) -> [Item] {
        guard let snapshot else {
            return []
        }

        return items(in: snapshot).filter { isHidden($0) == hidden }
    }
}
