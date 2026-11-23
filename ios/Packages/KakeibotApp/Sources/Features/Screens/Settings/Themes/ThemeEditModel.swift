import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ThemeEditModel {
    public var draft: ThemeDraft

    public internal(set) var errorNotice = ErrorNotice()

    let baseline: ThemeDraft?
    let editingId: Theme.ID?

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        editing theme: Theme?,
        base palette: ThemePalette
    ) {
        let draft = theme.map(ThemeDraft.init) ?? ThemeDraft(name: "", palette: palette)

        self.draft = draft
        self.baseline = draft
        self.database = database
        self.editingId = theme?.id
    }
}

public extension ThemeEditModel {
    enum Slot: CaseIterable, Sendable {
        case background
        case surface
        case text
        case subtext
        case accent
    }

    var palette: ThemePalette {
        draft.palette ?? .night
    }

    func isAvailable(
        _ hex: String,
        for slot: Slot
    ) -> Bool {
        if slot == .surface {
            return Self.isLight(hex) == Self.isLight(draft.background)
        }

        var draft = draft

        draft[keyPath: slot.keyPath] = hex

        return Self.isReadable(draft, slot)
    }

    func choose(
        _ hex: String,
        for slot: Slot
    ) {
        var next = draft

        next[keyPath: slot.keyPath] = hex

        if slot == .background,
           Self.isLight(next.surface) != Self.isLight(hex) {
            next.surface = Self.pairedSurface(for: hex)
        }

        for other in Slot.allCases where !Self.isReadable(next, other) {
            let readable = other.swatches.first { swatch in
                var candidate = next

                candidate[keyPath: other.keyPath] = swatch

                return Self.isReadable(candidate, other)
            }

            if let readable {
                next[keyPath: other.keyPath] = readable
            }
        }

        draft = next
    }

    func save() async -> Bool {
        do {
            let theme = try await database.saveTheme(
                draft,
                editing: editingId,
                at: Date()
            )

            if editingId == nil {
                try await database.setSetting(.theme, to: .custom(theme.id))
            }

            return true
        } catch {
            errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId else {
            return nil
        }

        do {
            return try await database.deleteTheme(editingId)
        } catch {
            errorNotice.show(SettingsEditMessage.deleteFailed, for: error)
            return nil
        }
    }
}

public extension ThemeEditModel.Slot {
    var title: String {
        switch self {
        case .background: "背景"
        case .surface: "カード"
        case .text: "文字"
        case .subtext: "補足の文字"
        case .accent: "アクセント"
        }
    }

    var roles: Set<ThemePalette.Role> {
        switch self {
        case .background, .surface: []
        case .text: [.text]
        case .subtext: [.subtext, .hint]
        case .accent: [.accent, .accentStrong]
        }
    }

    var keyPath: WritableKeyPath<ThemeDraft, String> {
        switch self {
        case .background: \.background
        case .surface: \.surface
        case .text: \.text
        case .subtext: \.subtext
        case .accent: \.accent
        }
    }

    var swatches: [String] {
        switch self {
        case .background:
            [
                "#16223D", "#1D1D20", "#143C32", "#0F3B44", "#3A1220",
                "#2C1A36", "#F8F4EB", "#FFFFFF", "#EEF4FA", "#EEF3EA",
                "#F8EEEC", "#F4E8C8", "#2A2118", "#1F2A33", "#2B2440",
                "#F1EEF8", "#EAF6F2", "#FBF0E6", "#F2F2F2", "#FDF3F6"
            ]

        case .surface:
            [
                "#141C2F", "#18181B", "#12322A", "#0E333B", "#2E0F1A",
                "#26162E", "#FFFFFF", "#F5EFE3", "#F0F5FA", "#F2F6EF",
                "#F8EEEB", "#FFF8E6", "#231B13", "#1A232B", "#241E37",
                "#F8F6FC", "#F4FBF8", "#FFF8F0", "#FAFAFA", "#FFF9FB"
            ]

        case .text:
            [
                "#EDE6D6", "#ECECEA", "#F0F5F2", "#2A2418", "#1E1E22",
                "#17233A", "#F3EAF7", "#EAF2F8", "#2E2238", "#1F2E2A"
            ]

        case .subtext:
            [
                "#8C97AE", "#9A9CA3", "#8FB0A3", "#6B6152", "#63636B",
                "#54627A", "#A99BB8", "#94A9B8", "#6E6178", "#5E6E68"
            ]

        case .accent:
            [
                "#CDAA6B", "#C9CCD2", "#D9966A", "#7FD1B9", "#E3A3A3",
                "#8A6420", "#2F5A8C", "#2F6A55", "#9C3D52", "#6E4E1C",
                "#B79BE0", "#E7C35A", "#7FB3E0", "#F2A0C0", "#5B3F8C",
                "#B4572E", "#2F7A8C", "#A8456E"
            ]
        }
    }
}

private extension ThemeEditModel {
    static func isLight(_ hex: String) -> Bool {
        let rgb = UInt32(hex.dropFirst(), radix: 16) ?? 0
        let onBlack = ThemePalette.contrast(rgb, 0x000000)
        let onWhite = ThemePalette.contrast(rgb, 0xFFFFFF)
        return onBlack > onWhite
    }

    static func pairedSurface(for background: String) -> String {
        let backgrounds = Slot.background.swatches
        let surfaces = Slot.surface.swatches

        if let index = backgrounds.firstIndex(of: background) {
            return surfaces[index]
        }

        let isLight = isLight(background)

        return surfaces.first { Self.isLight($0) == isLight } ?? background
    }

    static func isReadable(
        _ draft: ThemeDraft,
        _ slot: Slot
    ) -> Bool {
        guard let palette = draft.palette else {
            return false
        }

        return slot.roles.isDisjoint(with: palette.unreadableRoles)
    }
}

extension ThemeEditModel: SettingsEditModel {
    var edited: ThemeDraft {
        draft
    }

    var problemMessage: String? {
        draft.problems.first?.message
    }
}
