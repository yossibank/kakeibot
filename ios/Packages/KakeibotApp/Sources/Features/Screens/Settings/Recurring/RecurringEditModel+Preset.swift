import Core

public extension RecurringEditModel {
    var presets: [RecurringPreset] {
        RecurringPreset.presets(for: type)
    }

    func apply(_ preset: RecurringPreset) {
        frequency = preset.month == nil ? .monthly : .yearly
        month = preset.month ?? month
        day = preset.day
        memo = preset.title

        choose(preset.holidayShift)

        if let kind = preset.destination {
            applyDestination(kind)
        } else if let category = category(for: preset) {
            select(category: category.id)
        }
    }
}

private extension RecurringEditModel {
    static let cardClosingDay = 31

    func category(for preset: RecurringPreset) -> EntryCategory? {
        let named = categories.first { preset.categoryNames.contains($0.name) }

        let drawn = categories.first { category in
            icon(for: category)?.glyph.map(preset.glyphs.contains) == true
        }

        return named ?? drawn
    }

    func applyDestination(_ kind: Wallet.Kind) {
        let destination = wallets.first { $0.kind == kind }

        toWalletId = destination?.id
        closingDay = nil

        guard let destination else {
            return
        }

        if kind == .card {
            closingDay = Self.cardClosingDay
            memo = destination.name
        }

        let bank = wallets.first { $0.kind == .bank && $0.id != destination.id }
        let other = wallets.first { $0.id != destination.id }

        walletId = (bank ?? other)?.id
    }
}
