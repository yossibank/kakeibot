public struct ScreenWait: Sendable {
    private let sleep: @Sendable (Duration) async throws -> Void

    public init(_ sleep: @escaping @Sendable (Duration) async throws -> Void) {
        self.sleep = sleep
    }
}

public extension ScreenWait {
    static let system = ScreenWait { duration in
        try await Task.sleep(for: duration)
    }

    /// 頼まれた長さに関わらず、決めた長さだけ待つ。部品が持つ既定の長さを、画面ごとに変えるために使う。
    func lasting(_ duration: Duration) -> ScreenWait {
        let sleep = sleep

        return ScreenWait { _ in
            try await sleep(duration)
        }
    }

    @MainActor
    @discardableResult
    func after(
        _ duration: Duration,
        perform action: @escaping @MainActor () -> Void
    ) -> Task<Void, Never> {
        Task { @MainActor in
            guard await (try? sleep(duration)) != nil, !Task.isCancelled else {
                return
            }

            action()
        }
    }
}
