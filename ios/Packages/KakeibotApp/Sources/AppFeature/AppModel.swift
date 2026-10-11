import Observation
import Store
import SwiftUI

@MainActor
@Observable
final class AppModel {
    private(set) var launch: Launch = .opening

    private let openDatabase: () throws -> AppDatabase

    init(openDatabase: @escaping () throws -> AppDatabase) {
        self.openDatabase = openDatabase
    }
}

extension AppModel {
    enum Launch {
        case opening
        case ready(AppDatabase)
        case failed(String)
    }

    func open() {
        guard case .opening = launch else {
            return
        }

        do {
            let database = try openDatabase()
            launch = .ready(database)
        } catch {
            launch = .failed(String(describing: error))
        }
    }

    func changeScene(to phase: ScenePhase) {
        switch phase {
        case .background: AppDatabase.suspend()
        default: AppDatabase.resume()
        }
    }
}
