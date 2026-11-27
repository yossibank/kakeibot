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
        private(set) var curtain: Curtain = .covering
        private(set) var hasSwept = false
        private(set) var isHomeLoaded = false
        private(set) var observationRound = 0

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
        guard !hasSwept else {
            return
        }

        hasSwept = true
    }

    func leaveCurtain() {
        guard curtain == .covering else {
            return
        }

        curtain = .leaving
    }

    func finishCurtain() {
        guard curtain != .finished else {
            return
        }

        curtain = .finished
    }

    func markHomeLoaded() {
        guard !isHomeLoaded else {
            return
        }

        isHomeLoaded = true
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
        observationRound += 1
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
