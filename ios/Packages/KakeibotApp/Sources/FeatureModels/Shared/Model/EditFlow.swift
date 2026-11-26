import Core
import Observation

@MainActor
@Observable
public final class EditFlow<Saved: Sendable> {
    public let state: State
    public let output: Output

    let connection: Connection

    init() {
        let connection = Connection()

        self.state = State()
        self.output = Output(connection: connection)
        self.connection = connection
    }
}

public extension EditFlow {
    enum Prompt: Hashable, Sendable {
        case menu
        case discard
        case hideChanges
        case hide
        case delete
    }

    struct Outcome: Sendable {
        public let saved: Saved?
        public let isHidden: Bool?
        public let deletion: Deletion?
        public let closes: Bool

        init(
            saved: Saved? = nil,
            isHidden: Bool? = nil,
            deletion: Deletion? = nil,
            closes: Bool = true
        ) {
            self.saved = saved
            self.isHidden = isHidden
            self.deletion = deletion
            self.closes = closes
        }
    }

    @MainActor
    @Observable
    final class State {
        public var prompt = Shown<Prompt>()

        public internal(set) var outcome = ScreenOutcome<Outcome>()

        public let task = ModelTask()
    }

    @MainActor
    final class Output {
        let connection: Connection

        init(connection: Connection) {
            self.connection = connection
        }
    }
}

extension EditFlow {
    @MainActor
    final class Connection {
        weak var source: (any EditFlowSource<Saved>)?
    }
}

public extension EditFlow {
    func close() {
        _ = connection.source?.rest()

        if output.isChanged {
            state.prompt.show(.discard)
        } else {
            state.outcome.send(Outcome())
        }
    }

    func discard() {
        state.prompt.close(.discard)
        state.outcome.send(Outcome())
    }

    @discardableResult
    func save() -> Task<Void, Never> {
        Task {
            await run { source in
                guard let saved = await store(in: source) else {
                    return
                }

                if !source.keepsOpen(after: saved) {
                    finish(saved: saved)
                }
            }
        }
    }
}

extension EditFlow {
    func connect(_ source: any EditFlowSource<Saved>) {
        connection.source = source
    }

    func finish(saved: Saved) {
        state.outcome.send(Outcome(saved: saved))
    }

    func run(_ work: @MainActor (any EditFlowSource<Saved>) async -> Void) async {
        guard
            let source = connection.source,
            !state.task.isRunning
        else {
            return
        }

        await state.task.attempt {
            await work(source)
        }
    }

    func store(in source: any EditFlowSource<Saved>) async -> Saved? {
        _ = source.rest()

        if let problem = source.problem {
            source.state.errorNotice.show(problem)
            return nil
        }

        return await source.store()
    }
}

public extension EditFlow.Output {
    var isEditing: Bool {
        connection.source?.isEditing ?? false
    }

    var isChanged: Bool {
        connection.source?.isChanged ?? false
    }

    var isHidden: Bool {
        connection.source?.isHidden ?? false
    }

    var canSave: Bool {
        connection.source?.problem == nil
    }

    var saveTitle: String {
        connection.source.map { $0.problem ?? $0.readyTitle } ?? ""
    }

    var asksBeforeHiding: Bool {
        guard let source = connection.source else {
            return false
        }

        return !source.isHidden && source.asksBeforeHiding
    }
}
