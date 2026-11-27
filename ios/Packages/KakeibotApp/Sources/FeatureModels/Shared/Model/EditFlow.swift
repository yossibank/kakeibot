import Core
import Observation

@MainActor
@Observable
public final class EditFlow<Saved: Sendable> {
    public let state: State
    public let output: Output

    let source: any EditFlowSource<Saved>

    init(source: some EditFlowSource<Saved>) {
        self.state = State()
        self.output = Output(source: source)
        self.source = source
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
        let source: any EditFlowSource<Saved>

        init(source: any EditFlowSource<Saved>) {
            self.source = source
        }
    }
}

public extension EditFlow {
    func close() {
        _ = source.rest()

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
    func finish(saved: Saved) {
        state.outcome.send(Outcome(saved: saved))
    }

    func run(_ work: @MainActor (any EditFlowSource<Saved>) async -> Void) async {
        guard !state.task.isRunning else {
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
        source.isEditing
    }

    var isChanged: Bool {
        source.isChanged
    }

    var isHidden: Bool {
        source.isHidden
    }

    var canSave: Bool {
        source.problem == nil
    }

    var saveTitle: String {
        source.problem ?? source.readyTitle
    }

    var asksBeforeHiding: Bool {
        !source.isHidden && source.asksBeforeHiding
    }
}
