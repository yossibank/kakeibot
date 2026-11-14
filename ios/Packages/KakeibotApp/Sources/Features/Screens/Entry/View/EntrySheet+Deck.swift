import Core
import DesignSystem
import Store
import SwiftUI

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
            panelHeight = height
            slipGrowth = slipGrowth(forPanel: height)
        }
    }
}

extension EntrySheet {
    func show(_ next: EntryDeck) {
        let type = model.type
        let target: AmountTarget = next == .fee ? .fee : .amount

        if next != .amount,
           voice.step == .listening {
            cancelVoice()
        }

        deckEdge = next.order(for: type) >= deck.order(for: type)
            ? .trailing
            : .leading

        withAnimation(.snappy) {
            deck = next
            model.enter(target)
        }
    }

    func resetDeck() {
        deck = EntryDeck.start(for: model.type)
        model.enter(.amount)
    }

    func useRecent(_ entry: Entry) {
        model.applyRecent(entry)
        showSelectedCategory()
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
        as role: EntryWalletDeck.Role
    ) {
        switch role {
        case .source:
            model.walletId = wallet.id

        case .destination:
            model.toWalletId = wallet.id
        }

        if model.type == .transfer {
            show(.transfer)
        }
    }
}

private extension EntrySheet {
    typealias AmountTarget = EntryModel.KeypadTarget

    static let amountTitleHeight: CGFloat = 28
    static let panelInset: CGFloat = 12
    static let dateSpacing: CGFloat = 8
    static let maxKeyHeight: CGFloat = 64

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

    static var wellFill: some ShapeStyle {
        Palette.panel
            .mix(with: Palette.accent, by: 0.02)
            .shadow(.inner(color: Palette.shadow.opacity(.faint), radius: 4, y: 2))
    }

    var deckTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: deckEdge).combined(with: .opacity),
            removal: .move(edge: deckEdge == .trailing ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(20))
    }

    var dateBinding: Binding<LocalDate> {
        Binding(
            get: {
                model.date
            },
            set: { date in
                withAnimation(.snappy) {
                    model.date = date
                }
            }
        )
    }

    func slipGrowth(forPanel height: CGFloat) -> CGFloat {
        let spare = height + slipGrowth - Self.panelNeed
        return min(max(spare, 0), EntrySlip.growthLimit)
    }
}

private extension EntrySheet {
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
            EntryWalletDeck(model: model, role: role) { wallet in
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
                    choices: model.feeChoices,
                    selection: model.fee
                ) { amount in
                    model.setFee(amount)
                }
            } else if !voice.isActive {
                HStack(spacing: 8) {
                    Text("金額を入力")
                        .textFont(.caption2, weight: .bold)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 0)

                    if model.showsItems {
                        itemPill
                    }
                }
                .frame(height: Self.amountTitleHeight)
            }

            EntryLiveSlot {
                if voice.isActive {
                    voiceCard
                        .transition(.opacity)
                } else {
                    Keypad(
                        calculator: model.activeCalculator,
                        maxKeyHeight: Self.maxKeyHeight
                    ) { key in
                        model.press(key)
                    }
                }
            }
        }
        .animation(.snappy, value: voice.isActive)
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

                    ChipButton(quickDay.title, isSelected: model.date == date) {
                        dateBinding.wrappedValue = date
                    }
                }

                Spacer(minLength: 0)
            }

            MonthCalendar(
                selection: dateBinding,
                today: today,
                weekStart: model.weekStart,
                isCompact: true
            )
        }
    }
}

private extension EntrySheet {
    struct QuickDay {
        let title: String
        let offset: Int
    }

    static let quickDays = [
        QuickDay(title: "今日", offset: 0),
        QuickDay(title: "昨日", offset: -1),
        QuickDay(title: "おととい", offset: -2)
    ]
}
