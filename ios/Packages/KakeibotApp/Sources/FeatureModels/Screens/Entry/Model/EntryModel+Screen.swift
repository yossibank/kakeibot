import Core

public extension EntryModel {
    enum Deck: Hashable, Sendable {
        case category
        case transfer
        case amount
        case fee
        case wallet(WalletRole)
        case date

        public static func fields(for type: Entry.Kind) -> [Self] {
            switch type {
            case .transfer: [.transfer, .fee, .date, .amount]
            case .expense, .income: [.category, .wallet(.source), .date, .amount]
            }
        }

        public static func start(for type: Entry.Kind) -> Self {
            type == .transfer ? .transfer : .category
        }

        public func field(for type: Entry.Kind) -> Self {
            switch (self, type) {
            case (.wallet, .transfer): .transfer
            default: self
            }
        }

        public func order(for type: Entry.Kind) -> Int {
            let target = field(for: type)
            return Self.fields(for: type).firstIndex(of: target) ?? 0
        }
    }

    enum Sheet: Hashable, Identifiable, Sendable {
        case newWallet(WalletRole)
        case editWallet(Wallet.ID)
        case items
        case newItem
        case newCategory
        case editCategory(EntryCategory)
        case addTag(EntryCategory)
        case newTemplate
        case categories

        public var id: Self {
            self
        }

        var isWallet: Bool {
            switch self {
            case .newWallet, .editWallet: true
            default: false
            }
        }
    }

    struct WalletDeck: Equatable, Sendable {
        public internal(set) var isEditing = false
        public internal(set) var isBillOpen = false
        public internal(set) var isBillShown = false
    }

    struct Screen {
        public var categoryPage: Int? = 0
        public var sheet: Sheet?
        public var isConfirmingDiscard = false

        public internal(set) var wallets = WalletDeck()
        public internal(set) var deck: Deck
        public internal(set) var isForward = true
        public internal(set) var isEditingMemo = false
        public internal(set) var menuCategory: EntryCategory?

        var addedWallet: AddedWallet?
        var reloadsWallets = false

        init(deck: Deck) {
            self.deck = deck
        }
    }

    func showSelectedCategory() {
        let page = output.categoryPages.firstIndex { page in
            page.contains { $0.categoryId == state.category.id }
        }

        if state.screen.categoryPage != page ?? 0 {
            state.screen.categoryPage = page ?? 0
        }
    }

    func reloadAfterSheet() async {
        let added = state.screen.addedWallet
        let needsWallets = state.screen.reloadsWallets

        state.screen.addedWallet = nil
        state.screen.reloadsWallets = false

        await reloadAfterSheet(wallets: needsWallets, adding: added)
    }
}

public extension EntryModel.State {
    func show(_ next: EntryModel.Deck) {
        let isNew = next != screen.deck

        screen.isForward = next.order(for: type) >= screen.deck.order(for: type)
        screen.deck = next

        if isNew, case .wallet = next {
            screen.wallets = EntryModel.WalletDeck()
        }

        enter(next == .fee ? .fee : .amount)
    }

    func place(_ deck: EntryModel.Deck) {
        if screen.deck != deck {
            screen.deck = deck
        }
    }

    func resetDeck() {
        screen.deck = EntryModel.Deck.start(for: type)

        enter(.amount)
    }

    func editMemo(_ isEditing: Bool) {
        if screen.isEditingMemo != isEditing {
            screen.isEditingMemo = isEditing
        }
    }

    func openMenu(for category: EntryCategory) {
        screen.menuCategory = category
    }

    func closeMenu() {
        if screen.menuCategory != nil {
            screen.menuCategory = nil
        }
    }

    func toggleWalletEditing() {
        screen.wallets.isEditing.toggle()
    }

    func openBills(_ isOpen: Bool) {
        if screen.wallets.isBillOpen != isOpen {
            screen.wallets.isBillOpen = isOpen
        }
    }

    func showBills(_ isShown: Bool) {
        if screen.wallets.isBillShown != isShown {
            screen.wallets.isBillShown = isShown
        }
    }

    func open(_ sheet: EntryModel.Sheet) {
        screen.sheet = sheet
        screen.reloadsWallets = sheet.isWallet
    }

    func noteAdded(
        _ wallet: Wallet,
        as role: EntryModel.WalletRole
    ) {
        screen.addedWallet = EntryModel.AddedWallet(wallet: wallet, role: role)
    }

    func confirmDiscard() {
        screen.isConfirmingDiscard = true
    }
}
