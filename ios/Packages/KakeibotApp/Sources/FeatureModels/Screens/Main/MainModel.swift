import Core
import Observation

@MainActor
@Observable
public final class MainModel: ScreenPerforming {
    public let state: State
    public let input: Input

    let dependencies: Dependencies

    public convenience init(
        parts: ScreenParts,
        today: LocalDate
    ) {
        self.init(
            parts: parts,
            today: today,
            closeDelay: Self.sheetCloseDelay,
            warmupDuration: Self.entryWarmupDuration
        )
    }

    init(
        parts: ScreenParts,
        today: LocalDate,
        closeDelay: Duration,
        warmupDuration: Duration
    ) {
        let draft = EntryModel(parts: parts, date: today)
        let undo = DeletionUndo(parts: parts)

        self.state = State(draft: draft, undo: undo)
        self.input = Input(today: today)

        self.dependencies = Dependencies(
            parts: parts,
            closeDelay: closeDelay,
            warmupDuration: warmupDuration
        )
    }
}

public extension MainModel {
    enum Tab: Hashable, Sendable {
        case home
        case records
        case review
        case assets
    }

    enum Sheet: Hashable, Identifiable, Sendable {
        case new
        case edit(Entry.ID)
        case settings
        case template(EntryTemplate)
        case newTemplate
        case templates
        case transfer
        case wallet(Wallet.ID)
        case recurring(Recurring.ID)
        case periodRecurrings
        case setup(SetupItem)
        case reward
        case whatsNew(seenVersion: String?)
    }

    struct Presented: ScreenEditable {
        public var sheet = Shown<Sheet>()
    }

    @MainActor
    struct Notices {
        public let undo: DeletionUndo

        public private(set) var round = 0
    }

    @MainActor
    struct Submodels {
        public internal(set) var draft: EntryModel
    }

    @MainActor
    @Observable
    final class State {
        public var presented = Presented()

        public internal(set) var notices: Notices
        public internal(set) var submodels: Submodels
        public internal(set) var tabs = TabSelection()
        public internal(set) var entry = EntryLaunch()

        public let round = ObservationRound()

        @ObservationIgnored private var foreground = ForegroundReturn()

        init(
            draft: EntryModel,
            undo: DeletionUndo
        ) {
            self.notices = Notices(undo: undo)
            self.submodels = Submodels(draft: draft)
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var today: LocalDate
        public internal(set) var launchScreen: LaunchScreen?

        init(today: LocalDate) {
            self.today = today
        }
    }
}

extension MainModel {
    struct Dependencies {
        let parts: ScreenParts
        let closeDelay: Duration
        let warmupDuration: Duration
    }
}

public extension MainModel {
    static let sheetCloseDelay: Duration = .milliseconds(600)
    static let entryWarmupDuration: Duration = .milliseconds(500)
}

public extension MainModel.State {
    func select(_ tab: MainModel.Tab) {
        tabs.select(tab)
    }

    func changeScene(to phase: ForegroundReturn.Phase) {
        if foreground.receive(phase) {
            round.restart()
        }
    }

    func hideTabNotices() {
        notices.nextRound()
    }
}

extension MainModel.State {
    func finishWarmingEntry() {
        guard entry.isWarming else {
            return
        }

        entry.finishWarming()
    }

    func startReceipt() {
        entry.startReceipt()
    }

    func replaceDraft(with draft: EntryModel) {
        entry.clearReceipt()
        submodels.draft = draft
    }
}

public extension MainModel.Sheet {
    var id: Self {
        self
    }
}

extension MainModel.Notices {
    mutating func nextRound() {
        round += 1
    }
}
