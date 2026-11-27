import Core
import DesignSystem
import FeatureModels
import SwiftUI

private extension EntrySheet {
    struct QuickDay {
        let title: String
        let offset: Int
    }
}

extension EntrySheet {
    var deckPanel: some View {
        VStack(spacing: Self.panelInset) {
            ZStack(alignment: .top) {
                deckContent
                    .id(deck)
                    .transition(deckTransition)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .frame(maxWidth: .infinity)
            .clipped()

            if showsRecent {
                recentRow
            } else {
                saveButtons
            }
        }
        .padding(Self.panelInset)
        .background {
            panelShape
                .fill(Self.wellFill)
                .overlay {
                    panelShape
                        .strokeBorder(Palette.accent.opacity(.soft), lineWidth: 1)
                }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            layout.panelHeight = height

            if !model.state.screen.isEditingMemo {
                layout.slipGrowth = slipGrowth(forPanel: height)
            }
        }
    }

    func show(_ next: EntryModel.Deck) {
        if next != .amount,
           voice.state.presented.step == .listening {
            cancelVoice()
        }

        withAnimation(.snappy) {
            model.state.show(next)
        }
    }

    func useRecent(_ entry: Entry) {
        model.applyRecent(entry)
        model.showSelectedCategory()
        show(.amount)
    }

    func useTransfer(_ transfer: Entry) {
        withAnimation(.snappy) {
            model.applyTransfer(transfer)
        }

        show(.amount)
    }

    func choose(
        _ wallet: Wallet,
        as role: EntryWalletPanel.Role
    ) {
        model.choose(wallet.id, as: role)
        showTransferDeck()
    }

    func showTransferDeck() {
        if model.state.type == .transfer {
            show(.transfer)
        }
    }
}

private extension EntrySheet {
    static var wellFill: some ShapeStyle {
        Palette.panel
            .mix(with: Palette.accent, by: 0.02)
            .shadow(.inner(color: Palette.shadow.opacity(.faint), radius: 4, y: 2))
    }

    @ViewBuilder
    var deckContent: some View {
        switch deck {
        case .category:
            ScrollView {
                categoryArea
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)

        case .transfer:
            ScrollView {
                transferArea
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)

        case .amount, .fee:
            amountDeck

        case let .wallet(role):
            EntryWalletPanel(model: model, role: role) { wallet in
                choose(wallet, as: role)
            } onEdit: { wallet in
                open(.editWallet(wallet.id))
            } onAdd: {
                open(.newWallet(role))
            }

        case .date:
            ScrollView {
                dateDeck
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }

    var amountDeck: some View {
        VStack(spacing: 12) {
            if deck == .fee {
                FeeChoiceRow(
                    choices: model.output.feeChoices,
                    selection: model.output.fee
                ) { amount in
                    model.state.setFee(amount)
                }
            } else if !voice.output.isActive {
                HStack(spacing: 8) {
                    Text("金額を入力")
                        .textFont(.caption2, weight: .bold)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 0)

                    if model.output.showsItems {
                        itemPill
                    }
                }
                .frame(height: Self.amountTitleHeight)
            }

            EntryLiveSlot {
                if voice.output.isActive {
                    voiceCard
                        .transition(.opacity)
                } else {
                    Keypad(
                        calculator: model.output.activeCalculator,
                        maxKeyHeight: Self.maxKeyHeight
                    ) { key in
                        model.state.press(key)
                    }
                }
            }
        }
        .animation(.snappy, value: voice.output.isActive)
    }

    var itemPill: some View {
        Button {
            open(.newItem)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .textFont(.caption2, weight: .heavy)
                    .foregroundStyle(Palette.backgroundBottom)
                    .frame(width: 20, height: 20)
                    .background(Self.pillMark, in: .circle)

                Text("品目に分ける")
                    .textFont(.caption, weight: .bold)
                    .foregroundStyle(Palette.accent)
            }
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .padding(.vertical, 4)
            .background(Self.pillFill, in: .capsule)
            .overlay {
                Capsule()
                    .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    var dateDeck: some View {
        VStack(spacing: Self.dateSpacing) {
            HStack(spacing: 8) {
                ForEach(Self.quickDays, id: \.offset) { quickDay in
                    let date = today.adding(days: quickDay.offset)

                    ChipButton(quickDay.title, isSelected: model.state.payment.date == date) {
                        dateBinding.wrappedValue = date
                    }
                }

                Spacer(minLength: 0)
            }

            MonthCalendar(
                selection: dateBinding,
                today: today,
                weekStart: model.input.weekStart,
                isCompact: true
            )
        }
    }
}

private extension EntrySheet {
    static let amountTitleHeight: CGFloat = 28
    static let panelInset: CGFloat = 12
    static let dateSpacing: CGFloat = 8
    static let maxKeyHeight: CGFloat = 64

    static let quickDays = [
        QuickDay(title: "今日", offset: 0),
        QuickDay(title: "昨日", offset: -1),
        QuickDay(title: "おととい", offset: -2)
    ]

    static var panelNeed: CGFloat {
        let chips = ChipButton<ChipLabel>.Size.regular.height
        let calendar = MonthCalendar.height(isCompact: true)
        let dateDeck = chips + dateSpacing + calendar
        return panelInset * 3 + saveHeight + dateDeck
    }

    static var pillMark: LinearGradient {
        LinearGradient(
            colors: [Palette.accentStrong, Palette.accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var pillFill: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.subtle), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var deckTransition: AnyTransition {
        let isForward = model.state.screen.isForward
        let entering: Edge = isForward ? .trailing : .leading
        let leaving: Edge = isForward ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: entering).combined(with: .opacity),
            removal: .move(edge: leaving).combined(with: .opacity)
        )
    }

    var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(20))
    }

    var dateBinding: Binding<LocalDate> {
        Binding(
            get: {
                model.state.payment.date
            },
            set: { date in
                withAnimation(.snappy) {
                    model.state.setDate(date)
                }
            }
        )
    }

    func slipGrowth(forPanel height: CGFloat) -> CGFloat {
        let spare = height + layout.slipGrowth - Self.panelNeed
        return min(max(spare, 0), EntrySlip.growthLimit)
    }
}
