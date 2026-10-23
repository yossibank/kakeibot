import Core
import DesignSystem
import SwiftUI

public struct LaunchView: View {
    @State private var sweep: CGFloat = 0
    @State private var glow: Double = 0
    @State private var hasSwept = false
    @State private var revealSize: CGFloat = 0
    @State private var isLeaving = false

    @Environment(\.colorScheme) private var colorScheme

    let palette: ThemePalette
    let isReady: Bool
    let onLeave: () -> Void
    let onFinish: () -> Void

    public init(
        palette: ThemePalette,
        isReady: Bool,
        onLeave: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.palette = palette
        self.isReady = isReady
        self.onLeave = onLeave
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            mark

            themed
                .mask {
                    Circle()
                        .frame(width: revealSize, height: revealSize)
                }
        }
        .ignoresSafeArea()
        .opacity(isLeaving ? 0 : 1)
        .allowsHitTesting(!isLeaving)
        .task {
            await sweepRing()
        }
        .onChange(of: canReveal) {
            revealTheme()
        }
    }
}

private extension LaunchView {
    var mark: some View {
        let isDark = colorScheme == .dark
        let sweepColor = isDark ? Palette.accentStrong : Palette.accent

        return ZStack {
            Image("LaunchMark", bundle: .main)

            RingSweep(progress: sweep, length: Self.sweepLength)
                .stroke(
                    sweepColor,
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                )
                .frame(width: Self.ringSize, height: Self.ringSize)
                .shadow(color: Palette.accent, radius: 6)
        }
        .frame(width: Self.markSize, height: Self.markSize)
        .shadow(color: Palette.accent.opacity(glow), radius: 24)
        .environment(\.palette, sweepPalette)
    }

    var themed: some View {
        ZStack {
            Rectangle()
                .fill(Palette.background)

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

private extension LaunchView {
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
        hasSwept && isReady
    }

    func sweepRing() async {
        withAnimation(.easeInOut(duration: 0.8)) {
            sweep = 1 + Self.sweepLength
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
            glow = 0.7
        }

        try? await Task.sleep(for: .milliseconds(850))

        hasSwept = true
    }

    func revealTheme() {
        withAnimation(.easeIn(duration: 0.4)) {
            revealSize = Self.revealSize
        } completion: {
            leave()
        }
    }

    func leave() {
        onLeave()

        withAnimation(.easeOut(duration: 0.25)) {
            isLeaving = true
        } completion: {
            onFinish()
        }
    }
}

private struct RingSweep: Shape {
    var progress: CGFloat

    let length: CGFloat

    var animatableData: CGFloat {
        get {
            progress
        }
        set {
            progress = newValue
        }
    }

    func path(in rect: CGRect) -> Path {
        let start = min(max(progress - length, 0), 1)
        let end = min(max(progress, 0), 1)

        var path = Path()

        guard end > start else {
            return path
        }

        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(360 * start - 90),
            endAngle: .degrees(360 * end - 90),
            clockwise: false
        )

        return path
    }
}

#Preview {
    LaunchView(palette: .night, isReady: true) {} onFinish: {}
}
