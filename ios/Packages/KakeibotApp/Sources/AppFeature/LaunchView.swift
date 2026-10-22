import Core
import DesignSystem
import SwiftUI

public struct LaunchView: View {
    @State private var sweep: CGFloat = 0
    @State private var hasSwept = false
    @State private var revealSize: CGFloat = 0
    @State private var isLeaving = false

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
            Color("LaunchBackground", bundle: .main)

            Image("LaunchMark", bundle: .main)

            themed
                .mask {
                    Circle()
                        .frame(width: revealSize, height: revealSize)
                }

            RingSweep(progress: sweep, length: Self.sweepLength)
                .stroke(
                    Palette.accentStrong,
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                )
                .frame(width: Self.ringSize, height: Self.ringSize)
                .shadow(color: Palette.accent, radius: 6)
                .environment(\.palette, .night)
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

    var canReveal: Bool {
        hasSwept && isReady
    }

    func sweepRing() async {
        withAnimation(.easeInOut(duration: 0.45)) {
            sweep = 1 + Self.sweepLength
        }

        try? await Task.sleep(for: .milliseconds(450))
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

        withAnimation(.easeOut(duration: 0.15)) {
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
