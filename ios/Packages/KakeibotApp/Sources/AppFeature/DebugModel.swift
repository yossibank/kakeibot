#if DEBUG
    import Core
    import Foundation
    import Observation
    import Store

    @MainActor
    @Observable
    final class DebugModel {
        private(set) var entryCount = 0
        private(set) var lastError: String?

        private let database: AppDatabase
        private var writing: Task<Void, Never>?

        init(database: AppDatabase) {
            self.database = database
        }
    }

    extension DebugModel {
        var isWriting: Bool {
            writing != nil
        }

        func refresh() async {
            do {
                entryCount = try await database.entryCount()
            } catch {
                lastError = String(describing: error)
            }
        }

        func writeBatch() async {
            await write(count: Self.batchCount)
        }

        func toggleWriting() {
            if let writing {
                writing.cancel()
                self.writing = nil
                return
            }

            writing = Task {
                while !Task.isCancelled {
                    await write(count: Self.streamCount)
                    try? await Task.sleep(for: Self.streamInterval)
                }
            }
        }
    }

    private extension DebugModel {
        static let batchCount = 1000
        static let streamCount = 100
        static let streamInterval = Duration.milliseconds(200)

        func write(count: Int) async {
            let now = Date()
            let today = LocalDate(now, in: .current)

            do {
                try await database.writeSampleEntries(count: count, on: today, at: now)
                lastError = nil
            } catch {
                lastError = String(describing: error)
            }

            await refresh()
        }
    }
#endif
