import GRDB

actor EntryListJoin<Part: Equatable & Sendable, Value: Equatable & Sendable> {
    private var list: EntryList?
    private var part: Part?
    private var last: Value?

    private let continuation: AsyncThrowingStream<Value, any Error>.Continuation
    private let join: @Sendable (EntryList, Part) -> Value

    init(
        continuation: AsyncThrowingStream<Value, any Error>.Continuation,
        join: @escaping @Sendable (EntryList, Part) -> Value
    ) {
        self.continuation = continuation
        self.join = join
    }
}

extension EntryListJoin {
    static func updates(
        in database: AppDatabase,
        part: @escaping @Sendable (Database) throws -> Part,
        join: @escaping @Sendable (EntryList, Part) -> Value
    ) -> AsyncThrowingStream<Value, any Error> {
        AsyncThrowingStream { continuation in
            let state = EntryListJoin(continuation: continuation, join: join)

            let task = Task {
                do {
                    try await state.run(in: database, part: part)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

private extension EntryListJoin {
    nonisolated func run(
        in database: AppDatabase,
        part: @escaping @Sendable (Database) throws -> Part
    ) async throws {
        try await withThrowingDiscardingTaskGroup { group in
            group.addTask {
                for try await list in database.entryListUpdates() {
                    await self.receive(list: list)
                }
            }

            group.addTask {
                let parts = ValueObservation
                    .tracking(part)
                    .removeDuplicates()
                    .values(in: database.writer)

                for try await part in parts {
                    await self.receive(part: part)
                }
            }
        }
    }

    func receive(list: EntryList) {
        self.list = list
        publish()
    }

    func receive(part: Part) {
        self.part = part
        publish()
    }

    func publish() {
        guard
            let list,
            let part
        else {
            return
        }

        let value = join(list, part)

        guard value != last else {
            return
        }

        last = value
        continuation.yield(value)
    }
}
