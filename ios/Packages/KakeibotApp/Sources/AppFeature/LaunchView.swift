import Core
import DesignSystem
import SwiftUI

public struct LaunchView: View {
    @State private var sweep: CGFloat = 0
    @State private var glow: Double = 0
    @State private var hasSwept = false
    @State private var isLeaving = false

    let isThemed: Bool
    let isReady: Bool
    let onLeave: () -> Void
    let onFinish: () -> Void

    public init(
        isThemed: Bool,
        isReady: Bool,
        onLeave: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.isThemed = isThemed
        self.isReady = isReady
        self.onLeave = onLeave
        self.onFinish = onFinish
    }

    public var body: some View {
        let scale: CGFloat = isLeaving ? 1.12 : 1

        ZStack {
            Palette.panel

            mark
                .scaleEffect(scale)
        }
        .ignoresSafeArea()
        .opacity(isLeaving ? 0 : 1)
        .allowsHitTesting(!isLeaving)
        .task(id: isThemed) {
            guard isThemed else {
                return
            }

            await sweepRing()
        }
        .onChange(of: canLeave) {
            leave()
        }
    }
}

private extension LaunchView {
    var mark: some View {
        ZStack {
            Image("AppIconDial", bundle: .main)
                .resizable()
                .foregroundStyle(Palette.accent)

            Image("AppIconYen", bundle: .main)
                .resizable()
                .foregroundStyle(Palette.accentStrong)

            RingSweep(progress: sweep, length: Self.sweepLength)
                .stroke(
                    Palette.accentStrong,
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                )
                .frame(width: Self.ringSize, height: Self.ringSize)
                .shadow(color: Palette.accent, radius: 6)
        }
        .frame(width: Self.markSize, height: Self.markSize)
        .shadow(color: Palette.accent.opacity(glow), radius: 24)
    }
}

private extension LaunchView {
    static let markSize: CGFloat = 160
    static let ringSize: CGFloat = 160 * 694 / 1024
    static let sweepLength: CGFloat = 0.22

    var canLeave: Bool {
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

    func leave() {
        onLeave()

        withAnimation(.easeOut(duration: 0.45)) {
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
    LaunchView(isThemed: true, isReady: true) {} onFinish: {}
}
