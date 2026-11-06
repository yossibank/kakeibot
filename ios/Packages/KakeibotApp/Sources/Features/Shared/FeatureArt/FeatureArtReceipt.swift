import Core
import DesignSystem
import SwiftUI

struct FeatureArtReceipt: View {
    @Environment(\.themeStyle) private var themeStyle

    var showsViewfinder = false

    var body: some View {
        VStack(spacing: 4) {
            Text(FeatureArtSample.store)
                .font(.display(size: 9, weight: .bold, in: themeStyle.textFont))

            Text(FeatureArtSample.date)
                .font(.display(size: 6, in: themeStyle.textFont))
                .monospacedDigit()
                .opacity(0.6)

            rule

            ForEach(FeatureArtSample.items, id: \.self) { item in
                line(item.name, amount: item.amount)
            }

            rule

            line("合計", amount: FeatureArtSample.total)
                .font(.display(size: 8, weight: .bold, in: themeStyle.textFont))
        }
        .foregroundStyle(Self.ink)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(width: 96)
        .background {
            EntryReceiptShape(tooth: 6, hasTopEdge: true)
                .fill(Self.paper)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
        }
        .overlay {
            if showsViewfinder {
                FeatureArtViewfinder()
                    .stroke(Palette.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .padding(-9)

                Rectangle()
                    .fill(Self.scanBeam)
                    .frame(height: 10)
                    .offset(y: 6)
            }
        }
    }
}

private extension FeatureArtReceipt {
    static let ink = Color(white: 0.2)
    static let paper = Color(white: 0.985)

    static var scanBeam: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(0),
                Palette.accent.opacity(0.35),
                Palette.accent.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var rule: some View {
        Line()
            .stroke(Self.ink.opacity(0.4), style: StrokeStyle(lineWidth: 0.6, dash: [2, 2]))
            .frame(height: 1)
    }

    func line(
        _ name: String,
        amount: Int
    ) -> some View {
        HStack {
            Text(name)

            Spacer(minLength: 4)

            AmountText(amount, font: .fixed(.display(size: 8, in: themeStyle.displayFont)))
        }
        .font(.display(size: 8, in: themeStyle.textFont))
    }
}

private extension FeatureArtReceipt {
    struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}
