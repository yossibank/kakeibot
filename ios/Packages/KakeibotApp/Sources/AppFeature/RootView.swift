import Core
import DesignSystem
import Features
import Notifications
import Store
import SwiftUI

public struct RootView: View {
    @State private var model = AppModel(openDatabase: AppDatabase.appGroup)
    @State private var isLaunching = true
    @State private var isRevealed = false

    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ZStack {
            content

            if isLaunching {
                LaunchView(isReady: model.isOpened) {
                    isRevealed = true
                } onFinish: {
                    isLaunching = false
                }
            }
        }
        .task {
            await model.open()
            await model.observeTheme()
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
        .environment(\.notificationPermission, .live)
        .palette(isRevealed ? model.palette : .night)
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
                today: model.today
            ) {
                withAnimation(.snappy) {
                    model.finishOnboarding()
                }
            }
            .transition(.opacity)
        case let .ready(database):
            MainView(
                database: database,
                today: model.today,
                route: model.route
            ) {
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
