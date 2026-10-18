import Core
import Features
import Notifications
import Store
import SwiftUI

public struct RootView: View {
    @State private var model = AppModel(openDatabase: AppDatabase.appGroup)
    @State private var isLaunching = true

    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ZStack {
            content

            if isLaunching {
                LaunchView(isReady: model.isOpened) {
                    isLaunching = false
                }
            }
        }
        .task {
            await model.open()
        }
        .onChange(of: scenePhase) { _, phase in
            model.changeScene(to: phase)

            if phase == .active {
                Task {
                    await model.refreshDay()
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
        ) { _ in
            Task {
                await model.refreshDay()
            }
        }
        .warmsUpInput()
    }
}

private extension RootView {
    @ViewBuilder
    var content: some View {
        switch model.launch {
        case .opening:
            ProgressView()
        case let .onboarding(database):
            OnboardingView(
                database: database,
                today: LocalDate(Date(), in: .current)
            ) {
                withAnimation(.snappy) {
                    model.finishOnboarding()
                }
            }
            .transition(.opacity)
        case let .ready(database):
            MainView(database: database, route: model.route) {
                model.finishRoute()
            }
            .task {
                await model.observeNotifications(in: database)
            }
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
