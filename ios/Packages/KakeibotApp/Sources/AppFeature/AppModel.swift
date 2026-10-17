import Observation
import Store
import SwiftUI

@MainActor
@Observable
final class AppModel {
    private(set) var launch: Launch = .opening

    private let openDatabase: @Sendable () throws -> AppDatabase

    init(openDatabase: @escaping @Sendable () throws -> AppDatabase) {
        self.openDatabase = openDatabase
    }
}

extension AppModel {
    enum Launch {
        case opening
        case onboarding(AppDatabase)
        case ready(AppDatabase)
        case failed(String)
    }

    var isOpened: Bool {
        if case .opening = launch {
            false
        } else {
            true
        }
    }

    func open() async {
        guard case .opening = launch else {
            return
        }

        let openDatabase = openDatabase

        do {
            let database = try await Task.detached {
                try openDatabase()
            }
            .value

            let completed = try await database.isOnboardingCompleted()
            launch = completed ? .ready(database) : .onboarding(database)
        } catch {
            launch = .failed(String(describing: error))
        }
    }

    func finishOnboarding() {
        guard case let .onboarding(database) = launch else {
            return
        }

        launch = .ready(database)
    }

    func changeScene(to phase: ScenePhase) {
        switch phase {
        case .background: AppDatabase.suspend()
        default: AppDatabase.resume()
        }
    }
}
