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
    struct Notices: ScreenNotices {
        let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class State {
        let notices: Notices

        private(set) var launch: Launch = .opening
        private(set) var reveal = Reveal()

        let observation = ObservationRound()

        @ObservationIgnored private var foreground = ForegroundReturn()
        @ObservationIgnored private var stop = ObservationStop()

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
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

    @MainActor
    final class Runtime {
        var syncEngine: SyncEngine?
        var sharedSyncEngine: SyncEngine?
        var widgetReload: Task<Void, Never>?
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
        stop.stop()
    }

    func restartStoppedObservation() {
        guard stop.resume() else {
            return
        }

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
