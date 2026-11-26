import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct EntrySheet: View {
    @State var model: EntryModel
    @State var layout = Layout()
    @State var receipt = EntryReceiptFlow()
    @State var voice: EntryVoiceFlow

    @Environment(\.themeStyle.corner) var corner
    @Environment(\.isPro) var isPro
    @Environment(\.canScanReceipt) var canScanReceipt
    @Environment(\.openURL) var openURL

    @State private var notice: EntryNoticeModel

    @FocusState private var isMemoFocused: Bool

    @Environment(\.dismiss) private var dismiss

    private let onChange: (EntryChange) -> Void
    private let startsReceipt: Bool

    public init(
        model: EntryModel,
        startsReceipt: Bool = false,
        onChange: @escaping (EntryChange) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        _notice = State(initialValue: model.newNoticeModel())
        _voice = State(initialValue: model.newVoiceFlow())

        self.onChange = onChange
        self.startsReceipt = startsReceipt
    }

    public var body: some View {
        FloatingInputReader { proxy in
            ZStack(alignment: .top) {
                fittedContent(in: proxy.size.height)
                    .floatingInput(isPresented: model.state.screen.isEditingMemo) {
                        editMemo(false)
                    } card: {
                        EntryMemoCard(model: model, isFocused: $isMemoFocused) {
                            editMemo(false)
                        }
                    }

                if let category = model.state.screen.menuCategory {
                    categoryMenuLayer(category, at: layout.menuFrame)
                }

                receiptLayer

                voiceNoticeLayer(bottom: bannerBottom)
            }
            .coordinateSpace(.named(Self.coordinateSpace))
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                layout.sheetWidth = width
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.safeAreaInsets.bottom
            } action: { inset in
                layout.bottomInset = inset
            }
            .haptic(
                .impact(weight: .medium),
                trigger: model.state.screen.menuCategory
            ) { _, category in
                category != nil
            }
            .onChange(of: voice.output.isActive) {
                if voice.output.isActive {
                    show(.amount)
                }
            }
            .haptic(.impact(weight: .light), trigger: voice.state.startCount)
            .haptic(.impact(weight: .light), trigger: voice.state.endCount)
            .errorBanner(
                model.state.errorNotice,
                bottom: bannerBottom
            ) {
                model.state.errorNotice.clear()
            }
            .deletionNotice(
                Bindable(model.state).results.deletion,
                bottom: bannerBottom
            ) { deletion in
                model.perform {
                    await $0.restore(deletion)
                    await $0.reloadWallets()
                }
            }
            .settingsHideNotice(
                Bindable(model.state).results.hiddenCategory,
                bottom: bannerBottom
            ) { hidden in
                model.perform {
                    await $0.showCategory(hidden)
                }
            }
            .onOutcome(model.state.results.outcome) { outcome in
                receive(outcome)
            }
            .onOutcome(receipt.state.outcome) { outcome in
                receive(outcome)
            }
            .entryNotice(
                notice,
                above: bannerBottom - 12,
                clearsOnTap: false
            )
            .onChange(of: notice.state.notice) {
                if notice.state.notice == .undone {
                    model.perform {
                        await $0.reloadWallets()
                    }
                }
            }
            .proOffer(receipt.state.offer, presentsInSheet: true) {
                receipt.closeOffer()
            } onUnlock: {
                receipt.closeOffer()
            }
            .fullScreenCover(isPresented: isScanningReceipt) {
                receiptCamera
            }
            .backdrop()
            .modifier(
                EntryDiscardGuard(
                    isPresented: Bindable(model.state).screen.isConfirmingDiscard,
                    model: model
                ) {
                    dismiss()
                }
            )
            .sheet(item: Bindable(model.state).screen.sheet, onDismiss: reloadAfterSheet) { sheet in
                sheetContent(for: sheet)
            }
            .task {
                await model.start()
            }
            .task {
                await model.observeHistory()
            }
            .task {
                await voice.checkAvailability()
            }
            .modifier(EntryTodayFollower(model: model))
            .onDisappear {
                voice.perform {
                    await $0.cancel()
                }
            }
        }
    }
}

extension EntrySheet {
    struct Layout {
        var sheetWidth: CGFloat = 0
        var panelHeight: CGFloat = 0
        var slipGrowth: CGFloat = 0
        var bottomInset: CGFloat = 0
        var menuFrame: CGRect = .zero
    }
}

extension EntrySheet {
    nonisolated static let coordinateSpace = "EntrySheet"

    static let menuInset: CGFloat = 12
    static let liftInset: CGFloat = 12
    static let saveHeight: CGFloat = 56

    static var menuTransition: AnyTransition {
        .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity)
    }

    var deck: EntryModel.Deck {
        model.state.screen.deck
    }

    var today: LocalDate {
        model.state.today
    }

    init(
        model: EntryModel,
        deck: EntryModel.Deck
    ) {
        self.init(model: model)

        model.state.place(deck)
    }

    var saveButtons: some View {
        EntryLiveSlot {
            HStack(spacing: 8) {
                PrimaryButton(model.output.saveTitle) {
                    guard !opensKeypadOnSave else {
                        show(.amount)
                        return
                    }

                    model.perform {
                        await $0.save()
                    }
                }
                .disabled(!model.output.canSave && !opensKeypadOnSave)

                if model.output.isEditing {
                    sideButton(
                        "もう一度",
                        systemImage: "doc.on.doc",
                        isEnabled: true
                    ) {
                        model.perform {
                            await $0.recordAgain()
                        }
                    }
                } else {
                    sideButton(
                        "続けて",
                        systemImage: "plus.square.on.square",
                        isEnabled: model.output.canSave
                    ) {
                        model.perform {
                            await $0.saveAndContinue()
                        }
                    }
                }
            }
        }
    }

    func editMemo(_ isEditing: Bool) {
        if !isEditing {
            isMemoFocused = false
        }

        withAnimation(.snappy(duration: 0.25)) {
            model.state.editMemo(isEditing)
        }
    }

    func close() {
        if model.output.isChanged {
            model.state.confirmDiscard()
        } else {
            dismiss()
        }
    }

    func start(isFirst: Bool) {
        if isFirst {
            model.state.place(EntryModel.Deck.start(for: model.state.type))
        }

        model.showSelectedCategory()

        if startsReceipt, showsReceiptButton {
            withAnimation(.snappy) {
                receipt.start(for: model, isPro: isPro)
            }
        }
    }

    func finish(_ change: EntryChange) {
        onChange(change)
        dismiss()
    }

    func showNext(after change: EntryChange) {
        notice.show(change)
        show(EntryModel.Deck.start(for: model.state.type))
    }
}

private extension EntrySheet {
    var content: some View {
        VStack(spacing: 12) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 16)

            VStack(spacing: 0) {
                summary

                deckPanel
                    .padding(.horizontal, 8)
                    .padding(.bottom, bottomGap)
            }
            .padding(.horizontal, 8)
            .ignoresSafeArea(edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func fittedContent(in height: CGFloat) -> some View {
        if height > 0, height < fitHeight {
            ScrollView {
                content
                    .frame(height: fitHeight)
            }
            .scrollIndicators(.hidden)
        } else {
            content
        }
    }

    func sideButton(
        _ title: String,
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .sansFont(.body)

                Text(title)
                    .textFont(.caption2, weight: .semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Palette.accent)
            .frame(width: Self.continueWidth, height: Self.saveHeight)
            .overlay {
                Capsule()
                    .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

private extension EntrySheet {
    static let continueWidth: CGFloat = 64
    static let fitBase: CGFloat = 692

    var bottomGap: CGFloat {
        layout.bottomInset > 0 ? 20 : 8
    }

    var fitHeight: CGFloat {
        Self.fitBase + bottomGap - layout.bottomInset
    }

    var bannerBottom: CGFloat {
        layout.panelHeight + bottomGap - layout.bottomInset + 4
    }

    var opensKeypadOnSave: Bool {
        deck != .amount && !model.output.isEditing && model.output.amount <= 0
    }
}

#Preview {
    let today = LocalDate(Date(), in: .current)

    if let parts = ScreenParts.preview() {
        EntrySheet(model: EntryModel(parts: parts, date: today))
    }
}
