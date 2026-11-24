import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ThemeEditModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        editing theme: Theme?,
        base palette: ThemePalette
    ) {
        let draft = theme.map(ThemeDraft.init) ?? ThemeDraft(name: "", palette: palette)
        let state = State(draft: draft)

        self.state = state
        self.input = Input(baseline: draft, editingId: theme?.id)
        self.output = Output(state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension ThemeEditModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public internal(set) var errorNotice = ErrorNotice()

        public var draft: ThemeDraft

        init(draft: ThemeDraft) {
            self.draft = draft
        }
    }

    @MainActor
    @Observable
    final class Input: SettingsEditInput {
        let baseline: ThemeDraft?
        let editingId: Theme.ID?

        init(
            baseline: ThemeDraft,
            editingId: Theme.ID?
        ) {
            self.baseline = baseline
            self.editingId = editingId
        }
    }

    @MainActor
    final class Output {
        let state: State

        public var palette: ThemePalette {
            state.draft.palette ?? .night
        }

        init(state: State) {
            self.state = state
        }

        public func isAvailable(
            _ hex: String,
            for slot: Slot
        ) -> Bool {
            if slot == .surface {
                return ThemeEditModel.isLight(hex) == ThemeEditModel.isLight(state.draft.background)
            }

            var draft = state.draft

            draft[keyPath: slot.keyPath] = hex

            return ThemeEditModel.isReadable(draft, slot)
        }
    }
}

extension ThemeEditModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }
}

public extension ThemeEditModel.State {
    func choose(
        _ hex: String,
        for slot: ThemeEditModel.Slot
    ) {
        var next = draft

        next[keyPath: slot.keyPath] = hex

        if slot == .background,
           ThemeEditModel.isLight(next.surface) != ThemeEditModel.isLight(hex) {
            next.surface = ThemeEditModel.pairedSurface(for: hex)
        }

        for other in ThemeEditModel.Slot.allCases where !ThemeEditModel.isReadable(next, other) {
            let readable = other.swatches.first { swatch in
                var candidate = next

                candidate[keyPath: other.keyPath] = swatch

                return ThemeEditModel.isReadable(candidate, other)
            }

            if let readable {
                next[keyPath: other.keyPath] = readable
            }
        }

        draft = next
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

    func save() async -> Bool {
        do {
            let theme = try await dependencies.database.saveTheme(
                state.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            if input.editingId == nil {
                try await dependencies.database.setSetting(.theme, to: .custom(theme.id))
            }

            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        do {
            return try await dependencies.database.deleteTheme(editingId)
        } catch {
            state.errorNotice.show(SettingsEditMessage.deleteFailed, for: error)
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

extension ThemeEditModel: SettingsEditGroups {
    var edited: ThemeDraft {
        state.draft
    }

    var problemMessage: String? {
        state.draft.problems.first?.message
    }
}
