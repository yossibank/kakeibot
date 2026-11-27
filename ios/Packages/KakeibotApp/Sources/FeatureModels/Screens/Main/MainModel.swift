import Core
import Observation

@MainActor
@Observable
public final class MainModel: ScreenPerforming {
    public let state: State
    public let input = Input()

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

        self.state = State(today: today, draft: draft, undo: undo)

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

    @MainActor
    @Observable
    final class State {
        public var presented = Shown<Sheet>()

        public private(set) var tab: Tab = .home
        public private(set) var visitedTabs: Set<Tab> = [.home]
        public private(set) var startsReceipt = false
        public private(set) var today: LocalDate
        public private(set) var draft: EntryModel
        public private(set) var isWarmingEntry = true
        public private(set) var noticeRound = 0

        public let undo: DeletionUndo
        public let round = ObservationRound()

        @ObservationIgnored private var foreground = ForegroundReturn()

        init(
            today: LocalDate,
            draft: EntryModel,
            undo: DeletionUndo
        ) {
            self.today = today
            self.draft = draft
            self.undo = undo
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var launchScreen: LaunchScreen?
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
        self.tab = tab
        visitedTabs.insert(tab)
    }

    func changeScene(to phase: ForegroundReturn.Phase) {
        if foreground.receive(phase) {
            round.restart()
        }
    }

    func hideTabNotices() {
        noticeRound += 1
    }
}

extension MainModel.State {
    func finishWarmingEntry() {
        guard isWarmingEntry else {
            return
        }

        isWarmingEntry = false
    }

    func startReceipt() {
        startsReceipt = true
    }

    func setToday(_ today: LocalDate) {
        self.today = today
    }

    func replaceDraft(with draft: EntryModel) {
        startsReceipt = false
        self.draft = draft
    }
}

public extension MainModel.Sheet {
    var id: Self {
        self
    }
}
