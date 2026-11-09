import Core
import DesignSystem
import SwiftUI

struct WhatsNewPagerScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .pagerSwipe:
            swipe

        case .pagerNext:
            page(isNext: true)

        default:
            page(isNext: false)
        }
    }
}

private extension WhatsNewPagerScene {
    static let firstTotal = 32400
    static let nextTotal = 18600

    var swipe: some View {
        page(isNext: false)
            .offset(x: -24)
            .opacity(0.6)
            .allowsHitTesting(false)
            .overlay {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Palette.accentStrong)
                    .shadow(color: Palette.shadow, radius: 3, y: 1)
            }
            .overlay(alignment: .bottom) {
                Image(systemName: "arrow.left")
                    .textFont(size: .small, weight: .bold)
                    .foregroundStyle(Palette.accent)
                    .offset(y: -4)
            }
    }

    func page(isNext: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                monthTab("11月払い", total: Self.firstTotal, isSelected: !isNext)
                monthTab("12月払い", total: Self.nextTotal, isSelected: isNext)
            }

            billRow(isNext: isNext)
        }
        .monospacedDigit()
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    func monthTab(
        _ title: String,
        total: Int,
        isSelected: Bool
    ) -> some View {
        let label = isSelected ? Palette.backgroundBottom : Palette.text
        let note = isSelected ? Palette.backgroundBottom.opacity(.strong) : Palette.subtext
        let fill = isSelected ? Palette.accent : Palette.faint

        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(note)

            AmountText(total, font: .size(.micro, weight: .bold), color: label)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 36)
        .background(fill, in: .rect(cornerRadius: 8))
    }

    func billRow(isNext: Bool) -> some View {
        let total = isNext ? Self.nextTotal : Self.firstTotal
        let status = isNext ? BillText.estimate : BillText.settled

        return HStack(spacing: 4) {
            if isNext {
                BillRing(progress: 0.4)
            } else {
                BillMark(isOpen: false)
            }

            Text(status)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 2)

            AmountText(total, font: .size(.micro, weight: .semibold), color: Palette.text)
        }
        .textFont(size: .micro, weight: .semibold)
        .frame(height: 20)
    }
}
