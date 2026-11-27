import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct AppLaunchView: View {
    @State private var layout = Layout()

    @Environment(\.colorScheme) private var colorScheme

    let state: AppModel.State
    let palette: ThemePalette
    let isReady: Bool

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)

            mark

            themed
                .mask {
                    Circle()
                        .frame(width: layout.revealSize, height: layout.revealSize)
                }
        }
        .ignoresSafeArea()
        .opacity(layout.opacity)
        .allowsHitTesting(layout.opacity == 1)
        .task {
            await sweepRing()
        }
        .onChange(of: canReveal) {
            revealTheme()
        }
    }
}

private extension AppLaunchView {
    struct Layout {
        var sweep: CGFloat = 0
        var glow: Double = 0
        var revealSize: CGFloat = 0
        var opacity: Double = 1
    }
}

private extension AppLaunchView {
    var mark: some View {
        let isDark = colorScheme == .dark
        let sweepColor = isDark ? Palette.accentStrong : Palette.accent

        return ZStack {
            Image("LaunchMark", bundle: .main)

            RingSweep(progress: layout.sweep, length: Self.sweepLength)
                .stroke(
                    sweepColor,
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                )
                .frame(width: Self.ringSize, height: Self.ringSize)
                .glow(Palette.accent, radius: 6)
        }
        .frame(width: Self.markSize, height: Self.markSize)
        .glow(Palette.accent.opacity(layout.glow), radius: 24)
        .environment(\.palette, sweepPalette)
    }

    var themed: some View {
        ZStack {
            Backdrop()

            ZStack {
                Image("AppIconDial", bundle: .main)
                    .resizable()
                    .foregroundStyle(Palette.accent)

                Image("AppIconYen", bundle: .main)
                    .resizable()
                    .foregroundStyle(Palette.accentStrong)
            }
            .frame(width: Self.markSize, height: Self.markSize)
        }
        .environment(\.palette, palette)
    }
}

private extension AppLaunchView {
    static let markSize: CGFloat = 160
    static let ringSize: CGFloat = 160 * 694 / 1024
    static let sweepLength: CGFloat = 0.22
    static let revealSize: CGFloat = 1100

    var sweepPalette: ThemePalette {
        switch colorScheme {
        case .dark: .night
        default: ThemePreset.white.palette
        }
    }

    var canReveal: Bool {
        state.hasSwept && isReady
    }

    func sweepRing() async {
        withAnimation(.easeInOut(duration: 0.45)) {
            layout.sweep = 1 + Self.sweepLength
        }

        withAnimation(.easeOut(duration: 0.25).delay(0.25)) {
            layout.glow = 0.7
        }

        try? await Task.sleep(for: .milliseconds(450))
        state.finishSweep()
    }

    func revealTheme() {
        withAnimation(.easeIn(duration: 0.25)) {
            layout.revealSize = Self.revealSize
        } completion: {
            leave()
        }
    }

    func leave() {
        state.leaveCurtain()

        withAnimation(.easeOut(duration: 0.15)) {
            layout.opacity = 0
        } completion: {
            state.finishCurtain()
        }
    }
}

private struct RingSweep: Shape {
    var progress: CGFloat

    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        let start = min(max(progress - length, 0), 1)
        let end = min(max(progress, 0), 1)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle.degrees(360 * start - 90)
        let endAngle = Angle.degrees(360 * end - 90)
        var path = Path()

        guard end > start else {
            return path
        }

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

extension RingSweep {
    var animatableData: CGFloat {
        get {
            progress
        }
        set {
            progress = newValue
        }
    }
}

#Preview {
    AppLaunchView(state: AppModel.State(wait: .system), palette: .night, isReady: true)
}
