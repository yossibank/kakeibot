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
    @State private var isHomeLoaded = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            content

            if isLaunching {
                LaunchView(
                    palette: themePalette,
                    isReady: isLaunchReady
                ) {
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
        .onOpenURL { url in
            model.open(url)
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
        .palette(shownLook)
        .environment(\.palette, shownPalette)
        .environment(\.themeStyle, shownStyle)
        .font(shownStyle.bodyFont)
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
                route: model.route,
                isRevealed: !isLaunching
            ) {
                model.finishRoute()
            } onLoad: {
                isHomeLoaded = true
            }
            .task {
                await model.observeNotifications(in: database)
            }
            .task {
                await model.observeWidgets(in: database)
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

private extension RootView {
    var isLaunchReady: Bool {
        switch model.launch {
        case .opening: false
        case .ready: isHomeLoaded
        case .onboarding, .failed: true
        }
    }

    var shownLook: ThemeLook? {
        isRevealed ? model.look : nil
    }

    var themePalette: ThemePalette {
        let isDark = colorScheme == .dark

        return model.look.palette(isDark: isDark)
    }

    var shownPalette: ThemePalette {
        let isDark = colorScheme == .dark

        return shownLook?.palette(isDark: isDark) ?? .night
    }

    var shownStyle: ThemeStyle {
        isRevealed ? model.style : .standard
    }
}

#Preview {
    RootView()
}
