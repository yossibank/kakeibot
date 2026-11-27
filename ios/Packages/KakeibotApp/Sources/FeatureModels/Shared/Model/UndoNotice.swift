import Observation

@MainActor
@Observable
public final class UndoNotice<Item> {
    public private(set) var current: Item?
    public private(set) var id: Int?

    @ObservationIgnored private var count = 0
    @ObservationIgnored private var timer: Task<Void, Never>?

    @ObservationIgnored private let wait: ScreenWait

    public init(wait: ScreenWait) {
        self.wait = wait
    }
}

public extension UndoNotice {
    nonisolated static var duration: Duration {
        .seconds(4)
    }

    func show(
        _ item: Item,
        duration: Duration = UndoNotice.duration
    ) {
        count += 1

        let id = count

        current = item
        self.id = id
        timer?.cancel()

        timer = wait.after(duration) { [weak self] in
            guard let self, self.id == id else {
                return
            }

            clear()
        }
    }

    func dismiss() {
        timer?.cancel()
        timer = nil
        clear()
    }

    func take() -> Item? {
        let item = current
        dismiss()
        return item
    }
}

private extension UndoNotice {
    func clear() {
        current = nil
        id = nil
    }
}
