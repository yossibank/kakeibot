import Core
import DesignSystem
import SwiftUI

struct FeatureArtReceipt: View {
    var showsViewfinder = false

    var body: some View {
        VStack(spacing: 4) {
            Text(FeatureArtSample.store)
                .font(.system(size: 9, weight: .bold))

            Text(FeatureArtSample.date)
                .font(.system(size: 6))
                .monospacedDigit()
                .opacity(0.6)

            rule

            ForEach(FeatureArtSample.items, id: \.self) { item in
                line(item.name, amount: item.amount)
            }

            rule

            line("合計", amount: FeatureArtSample.total)
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(Self.ink)
        .padding(.horizontal, 9)
        .padding(.top, 9)
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

            Text(AmountText.text(amount))
                .monospacedDigit()
        }
        .font(.system(size: 8))
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

struct FeatureArtViewfinder: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(rect.width, rect.height) * 0.18

        return Path { path in
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
        }
    }
}

struct FeatureArtSlip: View {
    var showsRates = true
    var showsTotal = false
    var count = FeatureArtSample.items.count

    var body: some View {
        VStack(spacing: 6) {
            ForEach(FeatureArtSample.items.prefix(count), id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(item.name)
                        .foregroundStyle(Palette.text)
                        .fixedSize()

                    if showsRates {
                        EntryTaxRateBadge(rate: item.rate)
                    }

                    EntryReceiptLeader()

                    Text(AmountText.text(item.amount))
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                        .fixedSize()
                }
            }

            if showsTotal {
                EntryReceiptRule(style: .double)

                HStack(alignment: .firstTextBaseline) {
                    Text("合計")
                        .foregroundStyle(Palette.text)

                    Spacer(minLength: 4)

                    Text(AmountText.text(FeatureArtSample.total))
                        .displayFont(.small, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                }
            }
        }
        .textFont(size: .caption)
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 9 + Self.tooth / 2)
        .background {
            EntryReceiptShape(tooth: Self.tooth, hasTopEdge: false)
                .fill(Palette.paper)
                .shadow(color: Palette.shadow.opacity(0.4), radius: 3, y: 1)
        }
        .overlay {
            EntryReceiptShape(tooth: Self.tooth, hasTopEdge: false)
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
    }
}

private extension FeatureArtSlip {
    static let tooth: CGFloat = 6
}

struct FeatureArtPhone<Content: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(Palette.text.opacity(0.7))
                .frame(width: 22, height: 5)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 7)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(width: 84, height: 150)
        .background(Palette.background, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.text.opacity(0.75), lineWidth: 2.5)
        }
        .shadow(color: Palette.shadow.opacity(0.5), radius: 5, y: 2)
    }
}

struct FeatureArtMiniHome: View {
    var body: some View {
        FeatureArtCanvas(width: Self.width, height: Self.height) {
            screen
        }
    }
}

private extension FeatureArtMiniHome {
    static let width: CGFloat = 300
    static let height: CGFloat = 536
}

private extension FeatureArtMiniHome {
    var screen: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("11月")
                    .displayFont(.body)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)

                Text("11/1〜11/30")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 0)

                ForEach(["bell", "gearshape"], id: \.self) { symbol in
                    Image(systemName: symbol)
                        .sansFont(.body, weight: .light)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .stroke(Palette.outline, lineWidth: 1)
                        }
                }
            }

            dialCard

            recentCard

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    var dialCard: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottom) {
                HalfDial(progress: 0.62)

                VStack(spacing: 2) {
                    Text("今月あといくら")
                        .textFont(size: .caption)
                        .tracking(4)
                        .foregroundStyle(Palette.accent)

                    Text(AmountText.text(FeatureArtSample.remaining))
                        .displayFont(.title, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: 236)

            Text("予算 \(AmountText.text(200_000))")
                .textFont(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 0) {
                summary("今日の支出", amount: FeatureArtSample.todayExpense)

                summary("今月の支出", amount: FeatureArtSample.monthExpense)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .card()
    }

    var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最近の記録")
                .textFont(.caption)
                .tracking(3)
                .foregroundStyle(Palette.accent)

            ForEach(FeatureArtSample.items, id: \.self) { item in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Palette.accent.opacity(.subtle))
                        .frame(width: 26, height: 26)

                    Text(item.name)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)

                    Spacer(minLength: 0)

                    Text(AmountText.text(item.amount))
                        .displayFont(.body, weight: .medium)
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    func summary(
        _ title: String,
        amount: Int
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(amount))
                .displayFont(.body, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
        .frame(maxWidth: .infinity)
    }
}
