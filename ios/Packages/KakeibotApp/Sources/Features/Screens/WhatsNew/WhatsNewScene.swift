import Core
import DesignSystem
import SwiftUI

struct WhatsNewScene: View {
    @Environment(\.themeStyle.corner) private var corner

    let kind: Kind

    var body: some View {
        FeatureArtCanvas(width: Self.size, height: Self.size) {
            content
        }
        .padding(6)
        .background(Palette.faint, in: .rect(cornerRadius: corner.radius(14)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(14))
                .stroke(Palette.hairline, lineWidth: 1)
        }
    }
}

extension WhatsNewScene {
    enum Kind: Hashable, Sendable {
        case receiptButton
        case receiptCamera
        case receiptItems
        case itemsAdd
        case itemsSlip
        case itemsList
        case carryoverSwitch
        case carryoverLeft
        case carryoverNext
    }
}

private extension WhatsNewScene {
    static let size: CGFloat = 140
}

private extension WhatsNewScene {
    @ViewBuilder
    var content: some View {
        switch kind {
        case .receiptButton:
            tapped {
                EntryReceiptButton(freeLeft: nil) {}
            }
        case .receiptCamera:
            FeatureArtReceipt(showsViewfinder: true)
                .scaleEffect(0.95)
        case .receiptItems:
            VStack(spacing: 8) {
                FeatureArtSlip(showsRates: false)

                countBadge
            }
            .padding(.horizontal, 4)
        case .itemsAdd:
            tapped {
                Label("品目", systemImage: "plus")
                    .textFont(size: .caption, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 14)
                    .frame(height: 30)
                    .overlay {
                        Capsule()
                            .stroke(Palette.accent, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
            }
        case .itemsSlip:
            itemForm
        case .itemsList:
            FeatureArtSlip(showsRates: true, count: 2)
                .padding(.horizontal, 2)
        case .carryoverSwitch:
            carryoverSwitch
        case .carryoverLeft:
            carryoverLeft
        case .carryoverNext:
            carryoverNext
        }
    }

    var countBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "receipt")

            Text("品目 \(FeatureArtSample.items.count)件")

            Text(AmountText.text(FeatureArtSample.total))
                .monospacedDigit()
        }
        .textFont(size: .caption, weight: .semibold)
        .foregroundStyle(Palette.accentStrong)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Palette.accent.opacity(.subtle), in: .capsule)
    }

    var itemForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("品名")
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)

            Text("牛乳")
                .textFont(size: .small, weight: .semibold)
                .foregroundStyle(Palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(Palette.card, in: .rect(cornerRadius: 6))

            HStack(spacing: 4) {
                Text(AmountText.text(198))

                Text("×")
                    .foregroundStyle(Palette.hint)

                Text("2")

                Text("=")
                    .foregroundStyle(Palette.hint)

                Text(AmountText.text(396))
                    .foregroundStyle(Palette.accentStrong)
                    .bold()
            }
            .textFont(size: .caption, weight: .medium)
            .monospacedDigit()
            .foregroundStyle(Palette.text)
        }
        .padding(10)
        .background {
            EntryReceiptShape(tooth: 6, hasTopEdge: true, hasBottomEdge: false)
                .fill(Palette.paper)
        }
        .overlay {
            EntryReceiptShape(tooth: 6, hasTopEdge: true, hasBottomEdge: false)
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
        .padding(.horizontal, 6)
    }

    var carryoverSwitch: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("予算")
                .textFont(size: .micro, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            HStack {
                Text("残りを\n繰り越す")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.text)

                Spacer(minLength: 4)

                Capsule()
                    .fill(Palette.accent)
                    .frame(width: 40, height: 24)
                    .overlay(alignment: .trailing) {
                        Circle()
                            .fill(.white)
                            .shadow(color: Palette.shadow, radius: 1, y: 1)
                            .padding(2)
                    }
            }
        }
        .padding(12)
        .card(cornerRadius: 14)
        .padding(.horizontal, 4)
    }

    var carryoverLeft: some View {
        VStack(spacing: 6) {
            Text("11月の残り")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            ZStack(alignment: .bottom) {
                HalfDial(progress: 0.84)

                Text(AmountText.text(FeatureArtSample.carryover))
                    .displayFont(.body, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
            }
            .frame(width: 120, height: 60)
        }
    }

    var carryoverNext: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("12月")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accent)

            Text("予算 \(AmountText.text(FeatureArtSample.budget))")
                .textFont(size: .caption)
                .foregroundStyle(Palette.text)

            Text("＋ 繰越 \(AmountText.text(FeatureArtSample.carryover))")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accentStrong)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Palette.accent.opacity(.subtle), in: .capsule)

            Text(AmountText.text(FeatureArtSample.budget + FeatureArtSample.carryover))
                .displayFont(.headline, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }

    func tapped(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .allowsHitTesting(false)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Palette.accentStrong)
                    .shadow(color: Palette.shadow, radius: 3, y: 1)
                    .offset(x: 14, y: 26)
            }
    }
}
