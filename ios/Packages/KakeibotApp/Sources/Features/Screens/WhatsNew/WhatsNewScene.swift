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
        .padding(2)
        .background(Palette.faint, in: .rect(cornerRadius: corner.radius(12)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(12))
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
        case monthStartDay
        case monthStartShift
        case monthStartPeriod
        case unpaidRow
        case unpaidButton
        case unpaidList
        case shiftWallet
        case shiftChoice
        case shiftBill
        case recurringRow
        case recurringTabs
        case recurringList
        case loanCount
        case loanFinal
        case loanTotal
        case iconRow
        case iconButton
        case iconGrid
        case planTab
        case planButton
        case planList
        case pagerCard
        case pagerSwipe
        case pagerNext
        case walletAdd
        case walletKinds
        case walletMade
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
                    .padding(.horizontal, 12)
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

        case .monthStartDay:
            monthStartDay

        case .monthStartShift:
            tapped {
                monthStartShift
            }

        case .monthStartPeriod:
            monthStartPeriod

        case .unpaidRow, .unpaidButton, .unpaidList, .shiftWallet, .shiftChoice, .shiftBill:
            WhatsNewBillScene(kind: kind)

        case .recurringRow, .recurringTabs, .recurringList:
            WhatsNewRecurringScene(kind: kind)

        case .loanCount, .loanFinal, .loanTotal:
            WhatsNewLoanScene(kind: kind)

        case .iconRow, .iconButton, .iconGrid:
            WhatsNewIconScene(kind: kind)

        case .planTab, .planButton, .planList:
            WhatsNewPlanScene(kind: kind)

        case .pagerCard, .pagerSwipe, .pagerNext:
            WhatsNewPagerScene(kind: kind)

        case .walletAdd, .walletKinds, .walletMade:
            WhatsNewWalletScene(kind: kind)
        }
    }

    var countBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "receipt")

            Text("品目 \(FeatureArtSample.items.count)件")

            AmountText(FeatureArtSample.total, font: .size(.caption, weight: .semibold))
        }
        .textFont(size: .caption, weight: .semibold)
        .foregroundStyle(Palette.accentStrong)
        .padding(.horizontal, 8)
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
                .background(Palette.card, in: .rect(cornerRadius: 4))

            HStack(spacing: 4) {
                AmountText(198, font: .size(.caption, weight: .medium))

                Text("×")
                    .foregroundStyle(Palette.hint)

                Text("2")

                Text("=")
                    .foregroundStyle(Palette.hint)

                AmountText(396, font: .size(.caption, weight: .medium), color: Palette.accentStrong)
                    .bold()
            }
            .textFont(size: .caption, weight: .medium)
            .monospacedDigit()
            .foregroundStyle(Palette.text)
        }
        .padding(8)
        .background {
            EntryReceiptShape(tooth: 6, hasTopEdge: true, hasBottomEdge: false)
                .fill(Palette.paper)
        }
        .overlay {
            EntryReceiptShape(tooth: 6, hasTopEdge: true, hasBottomEdge: false)
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
        .padding(.horizontal, 4)
    }

    var carryoverSwitch: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var carryoverLeft: some View {
        VStack(spacing: 4) {
            Text("11月の残り")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            ZStack(alignment: .bottom) {
                HalfDial(progress: 0.84)

                AmountText(
                    FeatureArtSample.carryover,
                    font: .size(.body, weight: .bold),
                    color: Palette.accentStrong
                )
            }
            .frame(width: 120, height: 60)
        }
    }

    var carryoverNext: some View {
        let total = FeatureArtSample.budget + FeatureArtSample.carryover

        return VStack(alignment: .leading, spacing: 4) {
            Text("12月")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accent)

            Text("予算 \(AmountText.text(FeatureArtSample.budget))")
                .textFont(size: .caption)
                .foregroundStyle(Palette.text)

            Text("＋ 繰越 \(AmountText.text(FeatureArtSample.carryover))")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accentStrong)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Palette.accent.opacity(.subtle), in: .capsule)

            AmountText(total, font: .size(.headline, weight: .bold), color: Palette.accentStrong)
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }

    var monthStartDay: some View {
        VStack(spacing: 8) {
            Text("月の始まり")
                .textFont(size: .micro, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            HStack(spacing: 4) {
                ForEach(23...27, id: \.self) { day in
                    let isSelected = day == 25

                    Text("\(day)")
                        .textFont(size: .caption, weight: isSelected ? .bold : .regular)
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? Palette.backgroundTop : Palette.text)
                        .frame(width: 22, height: 22)
                        .background(isSelected ? Palette.accent : .clear, in: Circle())
                }
            }

            Text("毎月 25 日")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var monthStartShift: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("土日・祝日のとき")
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(Palette.accent)

            ForEach(HolidayShift.allCases, id: \.self) { shift in
                let isSelected = shift == .previous

                Text(shift.title)
                    .textFont(size: .caption, weight: isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Palette.accentStrong : Palette.subtext)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .background(SettingsTile.fill(isSelected: isSelected), in: .capsule)
                    .overlay {
                        Capsule()
                            .stroke(SettingsTile.stroke(isSelected: isSelected), lineWidth: 1)
                    }
            }
        }
        .padding(.horizontal, 12)
    }

    var monthStartPeriod: some View {
        VStack(spacing: 4) {
            Text("11月の始まり")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 4) {
                Text("25日(日)")
                    .strikethrough()
                    .foregroundStyle(Palette.hint)

                Image(systemName: "arrow.right")
                    .foregroundStyle(Palette.hint)

                Text("23日(金)")
                    .bold()
                    .foregroundStyle(Palette.accentStrong)
            }
            .textFont(size: .caption)

            Text("10/23〜11/24")
                .displayFont(.body, weight: .bold)
                .foregroundStyle(Palette.accentStrong)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Palette.accent.opacity(.subtle), in: .capsule)
        }
        .monospacedDigit()
    }

    func tapped(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .whatsNewTapped()
    }
}

extension View {
    func whatsNewTapped() -> some View {
        allowsHitTesting(false)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Palette.accentStrong)
                    .shadow(color: Palette.shadow, radius: 3, y: 1)
                    .offset(x: 14, y: 26)
            }
    }
}
