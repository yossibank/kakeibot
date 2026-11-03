import DesignSystem
import SwiftUI

struct EntryReceiptArt: View {
    @State private var isScanning = false

    let kind: Kind

    var body: some View {
        switch kind {
        case .flat:
            flat
        case .bright:
            bright
        case .edges:
            edges
        case .reading:
            reading
        }
    }
}

extension EntryReceiptArt {
    enum Kind: Hashable {
        case flat
        case bright
        case edges
        case reading
    }
}

private extension EntryReceiptArt {
    static let lineWidths: [CGFloat] = [0.7, 0.5, 0.8, 0.6]

    var flat: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Palette.accent.opacity(.subtle))
                .frame(height: 3)

            paper(width: 38, height: 50)
                .rotation3DEffect(
                    .degrees(48),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.6
                )
                .padding(.bottom, 4)
        }
        .frame(width: 56, height: 56)
    }

    var bright: some View {
        paper(width: 30, height: 42)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sun.max.fill")
                    .sansFont(.small)
                    .foregroundStyle(Palette.amber)
                    .offset(x: 14, y: -10)
            }
            .frame(width: 56, height: 56)
    }

    var edges: some View {
        paper(width: 28, height: 40)
            .padding(8)
            .overlay {
                FinderCorners(length: 9)
                    .stroke(
                        Palette.accent,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
            }
            .frame(width: 56, height: 56)
    }

    var reading: some View {
        paper(width: 72, height: 96)
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [
                            Palette.accent.opacity(0),
                            Palette.accent.opacity(.medium),
                            Palette.accent.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 18)
                    .offset(y: isScanning ? proxy.size.height - 18 : 0)
                }
                .clipShape(EntryReceiptShape(tooth: 6, hasTopEdge: true))
            }
            .padding(8)
            .overlay {
                FinderCorners(length: 14)
                    .stroke(
                        Palette.accent,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever()) {
                    isScanning = true
                }
            }
    }

    func paper(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let tooth = max(4, width / 8)

        return VStack(alignment: .leading, spacing: height / 14) {
            ForEach(Array(Self.lineWidths.enumerated()), id: \.offset) { _, ratio in
                Capsule()
                    .fill(Palette.subtext.opacity(.medium))
                    .frame(width: (width - 10) * ratio, height: max(1.5, height / 30))
            }

            Spacer(minLength: 0)

            VStack(spacing: 1) {
                Rectangle()
                    .fill(Palette.text.opacity(0.5))
                    .frame(height: 1)

                Rectangle()
                    .fill(Palette.text.opacity(0.5))
                    .frame(height: 1)
            }

            Capsule()
                .fill(Palette.accentStrong)
                .frame(width: (width - 10) * 0.45, height: max(2, height / 20))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .padding(.top, tooth)
        .padding(.bottom, tooth)
        .frame(width: width, height: height)
        .background {
            EntryReceiptShape(tooth: tooth, hasTopEdge: true)
                .fill(Palette.card)
                .shadow(color: Palette.shadow.opacity(0.5), radius: 3, y: 1)
        }
        .overlay {
            EntryReceiptShape(tooth: tooth, hasTopEdge: true)
                .stroke(Palette.outline, lineWidth: 0.5)
        }
    }
}

private struct FinderCorners: Shape {
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))

        return path
    }
}

#Preview {
    HStack(spacing: 16) {
        EntryReceiptArt(kind: .flat)

        EntryReceiptArt(kind: .bright)

        EntryReceiptArt(kind: .edges)

        EntryReceiptArt(kind: .reading)
    }
    .padding()
    .background(Palette.panel)
}
