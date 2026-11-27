import Observation

/// 実行中の印。どれを実行中かを見る時は、鍵の型を `ModelTask<Work>()` で決める。
/// 鍵の要らない時は `ModelTask()` と書き、鍵の型は `Never` になる。
@MainActor
@Observable
public final class ModelTask<Key: Hashable & Sendable> {
    private var running = 0
    private var keys: [Key: Int]

    public convenience init() {
        self.init(keys: [:])
    }

    private init(keys: [Key: Int]) {
        self.keys = keys
    }
}

public extension ModelTask where Key == Never {
    convenience init() {
        self.init(keys: [:])
    }
}

public extension ModelTask {
    var isRunning: Bool {
        running > 0
    }

    func isRunning(_ key: Key) -> Bool {
        keys[key] != nil
    }

    func isRunning(where matches: (Key) -> Bool) -> Bool {
        keys.keys.contains(where: matches)
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
        _ key: Key,
        _ action: @MainActor () async throws -> Value
    ) async rethrows -> Value {
        keys[key, default: 0] += 1

        defer {
            let count = (keys[key] ?? 1) - 1
            keys[key] = count > 0 ? count : nil
        }

        return try await attempt(action)
    }
}
