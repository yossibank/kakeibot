import Features
import Notifications
import Store
import SwiftUI

@MainActor
public struct RootView {
    @State private var model = AppModel(openDatabase: AppDatabase.appGroup)
    @Environment(\.scenePhase) private var scenePhase

    public init() {}
}

extension RootView: View {
    public var body: some View {
        content
            .task { model.open() }
            .onChange(of: scenePhase) { _, phase in
                model.changeScene(to: phase)
            }
    }
}

private extension RootView {
    @ViewBuilder
    var content: some View {
        switch model.launch {
        case .opening:
            ProgressView()
        case let .ready(database):
            ready(database)
        case let .failed(message):
            ContentUnavailableView(
                "データを開けませんでした",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    @ViewBuilder
    func ready(_ database: AppDatabase) -> some View {
        #if DEBUG
            DebugView(database: database)
        #else
            Text("Kakeibot")
        #endif
    }
}

#Preview {
    RootView()
}
