import Features
import Notifications
import Store
import SwiftUI

public struct RootView: View {
    @State private var model = AppModel(openDatabase: AppDatabase.appGroup)

    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        content
            .task { model.open() }
            .onChange(of: scenePhase) { _, phase in
                model.changeScene(to: phase)
            }
            .warmsUpKeyboard()
            .debugMenuOnShake()
    }
}

private extension RootView {
    @ViewBuilder
    var content: some View {
        switch model.launch {
        case .opening:
            ProgressView()
        case .ready:
            Text("Kakeibot")
        case let .failed(message):
            ContentUnavailableView(
                "データを開けませんでした",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }
}

#Preview {
    RootView()
}
