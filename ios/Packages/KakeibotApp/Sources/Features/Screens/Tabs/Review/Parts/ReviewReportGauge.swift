import Core
import DesignSystem
import SwiftUI

struct ReviewReportGauge: View {
    let pace: ReviewPace
    let limitName: String
    let showsMarker: Bool
    let size: CGFloat

    var body: some View {
        let used = min(pace.usedRatio, 1)
        let color = pace.verdict == .over ? Palette.increase : Palette.accent
        let track = StrokeStyle(lineWidth: lineWidth, lineCap: .round)

        ZStack {
            ReviewReportGaugeArc(progress: 1, inset: lineWidth / 2)
                .stroke(Palette.accent.opacity(.subtle), style: track)

            ReviewReportGaugeArc(progress: used, inset: lineWidth / 2)
                .stroke(color, style: track)

            ReviewReportGaugeTicks(count: 8, length: size / 26, inset: lineWidth + 6)
                .stroke(Palette.accent.opacity(.medium), lineWidth: 1.5)

            if showsMarker {
                needle

                markedLabel
            } else {
                centeredLabel
            }
        }
        .frame(width: size, height: size)
    }
}

extension ReviewReportGauge {
    static let regularSize: CGFloat = 160
    static let compactSize: CGFloat = 132
}

private extension ReviewReportGauge {
    var lineWidth: CGFloat {
        size / 16
    }

    var needleAngle: Double {
        let elapsed = min(max(pace.elapsedRatio, 0), 1)
        let sweep = ReviewReportGaugeArc.sweepDegrees
        return -sweep / 2 + sweep * elapsed
    }

    var percentText: String {
        "\(ReviewPace.percent(pace.usedRatio))%"
    }

    var needle: some View {
        ZStack {
            ReviewReportGaugeNeedle(length: size / 3, width: 3.6)
                .fill(Palette.text)
                .rotationEffect(.degrees(needleAngle))

            Circle()
                .fill(Palette.gold)
                .frame(width: 12, height: 12)

            Circle()
                .fill(Palette.cardBottom)
                .frame(width: 4, height: 4)
        }
    }

    var markedLabel: some View {
        VStack(spacing: 0) {
            Text("\(limitName)の")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(percentText)
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    var centeredLabel: some View {
        VStack(spacing: 0) {
            Text("\(limitName)の")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(percentText)
                .displayFont(.title, weight: .bold)
                .foregroundStyle(Palette.text)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("使いました")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
        }
        .padding(.horizontal, 20)
    }
}

private struct ReviewReportGaugeArc {
    let progress: Double
    let inset: CGFloat
}

extension ReviewReportGaugeArc: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - inset
        let start = Self.startDegrees
        let end = start + Self.sweepDegrees * progress

        return Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(start),
                endAngle: .degrees(end),
                clockwise: false
            )
        }
    }
}

private extension ReviewReportGaugeArc {
    static let startDegrees = 150.0
    static let sweepDegrees = 240.0
}

private struct ReviewReportGaugeTicks {
    let count: Int
    let length: CGFloat
    let inset: CGFloat
}

extension ReviewReportGaugeTicks: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2 - inset
        let inner = outer - length

        return Path { path in
            for index in 0...count {
                let ratio = Double(index) / Double(count)
                let sweep = ReviewReportGaugeArc.sweepDegrees * ratio
                let degrees = ReviewReportGaugeArc.startDegrees + sweep
                let radians = degrees * .pi / 180
                let start = Self.point(from: center, at: radians, radius: inner)
                let end = Self.point(from: center, at: radians, radius: outer)

                path.move(to: start)
                path.addLine(to: end)
            }
        }
    }
}

private extension ReviewReportGaugeTicks {
    static func point(
        from center: CGPoint,
        at radians: Double,
        radius: CGFloat
    ) -> CGPoint {
        let x = center.x + cos(radians) * radius
        let y = center.y + sin(radians) * radius
        return CGPoint(x: x, y: y)
    }
}

private struct ReviewReportGaugeNeedle {
    let length: CGFloat
    let width: CGFloat
}

extension ReviewReportGaugeNeedle: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)

        return Path { path in
            path.move(to: CGPoint(x: center.x - width / 2, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y - length))
            path.addLine(to: CGPoint(x: center.x + width / 2, y: center.y))
            path.closeSubpath()
        }
    }
}
