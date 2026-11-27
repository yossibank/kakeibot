import Observation

@MainActor
@Observable
public final class ModelTask {
    private var running = 0
    private var keys: [AnyHashable: Int] = [:]

    public init() {}
}

public extension ModelTask {
    var isRunning: Bool {
        running > 0
    }

    func isRunning(_ key: some Hashable & Sendable) -> Bool {
        keys[AnyHashable(key)] != nil
    }

    func isRunning<Key: Hashable & Sendable>(where matches: (Key) -> Bool) -> Bool {
        keys.keys.contains { ($0.base as? Key).map(matches) ?? false }
    }

    @discardableResult
    func attempt<Value>(_ action: @MainActor () async throws -> Value) async rethrows -> Value {
        running += 1

        defer {
            running -= 1
        }

        return try await action()
    }

    @discardableResult
    func attempt<Value>(
        _ key: some Hashable & Sendable,
        _ action: @MainActor () async throws -> Value
    ) async rethrows -> Value {
        let key = AnyHashable(key)

        keys[key, default: 0] += 1

        defer {
            let count = (keys[key] ?? 1) - 1
            keys[key] = count > 0 ? count : nil
        }

        return try await attempt(action)
    }
}
