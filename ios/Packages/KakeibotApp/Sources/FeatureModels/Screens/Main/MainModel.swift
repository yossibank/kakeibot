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
            closeDelay: Self.sheetCloseDelay
        )
    }

    init(
        parts: ScreenParts,
        today: LocalDate,
        closeDelay: Duration
    ) {
        let draft = EntryModel(parts: parts, date: today)

        self.state = State(today: today, draft: draft)
        self.dependencies = Dependencies(parts: parts, closeDelay: closeDelay)
    }
}

public extension MainModel {
    enum Tab: Hashable, Sendable {
        case home
        case records
        case review
        case assets
    }

    enum Sheet: Hashable, Identifiable {
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

        public var id: Self {
            self
        }
    }

    @MainActor
    @Observable
    final class State {
        public var sheet: Sheet?

        public private(set) var tab: Tab = .home
        public private(set) var visitedTabs: Set<Tab> = [.home]
        public private(set) var startsReceipt = false
        public private(set) var today: LocalDate
        public private(set) var draft: EntryModel

        init(
            today: LocalDate,
            draft: EntryModel
        ) {
            self.today = today
            self.draft = draft
        }

        public func select(_ tab: Tab) {
            self.tab = tab
            visitedTabs.insert(tab)
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

    @MainActor
    @Observable
    final class Input {
        public internal(set) var launchScreen: LaunchScreen?
    }

    static let sheetCloseDelay: Duration = .milliseconds(600)
}

extension MainModel {
    struct Dependencies {
        let parts: ScreenParts
        let closeDelay: Duration
    }
}
