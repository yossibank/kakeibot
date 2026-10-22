import Core
import SwiftUI

public struct BuddyFace: View {
    let buddy: Buddy
    let mood: BuddyMood
    let size: CGFloat

    public init(
        _ buddy: Buddy,
        mood: BuddyMood,
        size: CGFloat
    ) {
        self.buddy = buddy
        self.mood = mood
        self.size = size
    }

    public var body: some View {
        ZStack {
            ears

            face

            cheeks

            eyes

            mouth
        }
        .frame(width: size, height: size)
        .animation(.spring(duration: 0.4, bounce: 0.4), value: mood)
    }
}

private extension BuddyFace {
    var unit: CGFloat {
        size / 100
    }

    var face: some View {
        ZStack {
            Circle()
                .fill(Palette.card)

            DialTicks(count: 12, length: unit * 5)
                .stroke(Palette.accent.opacity(.strong), lineWidth: unit)
                .padding(unit * 5)

            Circle()
                .strokeBorder(Palette.accent, lineWidth: unit * 2.5)
        }
        .frame(width: unit * 82, height: unit * 82)
        .offset(y: unit * 8)
    }

    @ViewBuilder
    var ears: some View {
        switch buddy {
        case .dial:
            RoundedRectangle(cornerRadius: unit * 3)
                .fill(Palette.accent)
                .frame(width: unit * 16, height: unit * 12)
                .offset(y: -unit * 36)
        case .cat:
            pair { side in
                BuddyEar()
                    .fill(Palette.cardTop)
                    .overlay {
                        BuddyEar()
                            .stroke(Palette.accent, lineWidth: unit * 2.5)
                    }
                    .frame(width: unit * 30, height: unit * 30)
                    .rotationEffect(.degrees(side * 18))
                    .offset(x: side * unit * 26, y: -unit * 28)
            }
        case .rabbit:
            pair { side in
                Capsule()
                    .fill(Palette.cardTop)
                    .overlay {
                        Capsule()
                            .strokeBorder(Palette.accent, lineWidth: unit * 2.5)
                    }
                    .frame(width: unit * 18, height: unit * 44)
                    .rotationEffect(.degrees(side * 10))
                    .offset(x: side * unit * 17, y: -unit * 34)
            }
        case .bear:
            pair { side in
                Circle()
                    .fill(Palette.cardTop)
                    .overlay {
                        Circle()
                            .strokeBorder(Palette.accent, lineWidth: unit * 2.5)
                    }
                    .frame(width: unit * 28, height: unit * 28)
                    .offset(x: side * unit * 30, y: -unit * 26)
            }
        }
    }

    @ViewBuilder
    var cheeks: some View {
        if mood == .smile || mood == .cheer {
            pair { side in
                Circle()
                    .fill(Palette.rose.opacity(0.3))
                    .frame(width: unit * 11, height: unit * 11)
                    .offset(x: side * unit * 25, y: unit * 18)
            }
        }
    }

    var eyes: some View {
        pair { side in
            eye
                .offset(x: side * unit * 15, y: unit * 6)
        }
    }

    @ViewBuilder
    var eye: some View {
        switch mood {
        case .smile, .cheer:
            BuddyArc(start: 200, end: 340)
                .stroke(Palette.accentStrong, style: stroke)
                .frame(width: unit * 12, height: unit * 12)
                .offset(y: unit * 3)
        case .calm:
            Circle()
                .fill(Palette.accentStrong)
                .frame(width: unit * 7, height: unit * 7)
        case .worried, .sad:
            Circle()
                .fill(Palette.accentStrong)
                .frame(width: unit * 6, height: unit * 6)
                .offset(y: unit * 2)
        }
    }

    @ViewBuilder
    var mouth: some View {
        switch mood {
        case .smile:
            BuddyArc(start: 20, end: 160)
                .stroke(Palette.accentStrong, style: stroke)
                .frame(width: unit * 18, height: unit * 18)
                .offset(y: unit * 18)
        case .cheer:
            BuddyArc(start: 0, end: 180)
                .fill(Palette.accentStrong)
                .frame(width: unit * 18, height: unit * 18)
                .offset(y: unit * 20)
        case .calm:
            BuddyArc(start: 40, end: 140)
                .stroke(Palette.accentStrong, style: stroke)
                .frame(width: unit * 12, height: unit * 12)
                .offset(y: unit * 20)
        case .worried:
            Capsule()
                .fill(Palette.accentStrong)
                .frame(width: unit * 12, height: unit * 2.5)
                .offset(y: unit * 26)
        case .sad:
            BuddyArc(start: 220, end: 320)
                .stroke(Palette.accentStrong, style: stroke)
                .frame(width: unit * 14, height: unit * 14)
                .offset(y: unit * 32)
        }
    }

    var stroke: StrokeStyle {
        StrokeStyle(lineWidth: unit * 3, lineCap: .round)
    }

    func pair(@ViewBuilder _ content: (CGFloat) -> some View) -> some View {
        ZStack {
            content(-1)

            content(1)
        }
    }
}

private struct BuddyEar: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

private struct BuddyArc: Shape {
    let start: Double
    let end: Double

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: min(rect.width, rect.height) / 2,
                startAngle: .degrees(start),
                endAngle: .degrees(end),
                clockwise: false
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(Buddy.allCases, id: \.self) { buddy in
            HStack(spacing: 12) {
                ForEach(BuddyMood.allCases, id: \.self) { mood in
                    BuddyFace(buddy, mood: mood, size: 56)
                }
            }
        }
    }
    .padding()
    .background(Palette.background)
}
