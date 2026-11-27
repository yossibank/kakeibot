import Core
import DesignSystem
import FeatureModels
import Observation
import Store
import Sync

extension AppModel {
    enum Launch {
        case opening
        case onboarding(Opened)
        case ready(Opened)
        case failed
    }

    struct Opened {
        let database: AppDatabase
        let parts: ScreenParts
    }

    enum Curtain {
        case covering
        case leaving
        case finished
    }

    @MainActor
    @Observable
    final class State {
        let notice: ErrorNotice

        private(set) var launch: Launch = .opening
        private(set) var reveal = Reveal()

        let observation = ObservationRound()

        @ObservationIgnored var syncEngine: SyncEngine?
        @ObservationIgnored var sharedSyncEngine: SyncEngine?
        @ObservationIgnored var widgetReload: Task<Void, Never>?

        @ObservationIgnored private var foreground = ForegroundReturn()
        @ObservationIgnored private var hasStoppedObservation = false

        init(wait: ScreenWait) {
            self.notice = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class Input {
        var today: LocalDate
        var look: ThemeLook = .followsDevice
        var style: ThemeStyle = .standard
        var syncActivity = SyncActivity(isSyncEnabled: false, isSharing: false)
        var isPro = false

        init(today: LocalDate) {
            self.today = today
        }
    }
}

extension AppModel.State {
    func setLaunch(_ launch: AppModel.Launch) {
        self.launch = launch
    }

    func finishSweep() {
        guard !reveal.hasSwept else {
            return
        }

        reveal.finishSweep()
    }

    func leaveCurtain() {
        guard reveal.curtain == .covering else {
            return
        }

        reveal.leaveCurtain()
    }

    func finishCurtain() {
        guard reveal.curtain != .finished else {
            return
        }

        reveal.finishCurtain()
    }

    func markHomeLoaded() {
        guard !reveal.isHomeLoaded else {
            return
        }

        reveal.markHomeLoaded()
    }

    func receiveScene(_ phase: ForegroundReturn.Phase) -> Bool {
        foreground.receive(phase)
    }

    func markObservationStopped() {
        hasStoppedObservation = true
    }

    func restartStoppedObservation() {
        guard hasStoppedObservation else {
            return
        }

        hasStoppedObservation = false
        observation.restart()
    }
}

extension AppModel.Curtain {
    var isShown: Bool {
        self != .finished
    }

    var isRevealed: Bool {
        self != .covering
    }
}

extension AppModel.Launch {
    var database: AppDatabase? {
        switch self {
        case let .onboarding(opened), let .ready(opened): opened.database
        case .opening, .failed: nil
        }
    }
}
