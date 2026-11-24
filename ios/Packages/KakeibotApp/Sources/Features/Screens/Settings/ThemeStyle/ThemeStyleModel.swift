import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class ThemeStyleModel: SettingSaving {
    public let state: State
    public let output: Output

    let dependencies: Dependencies

    public init(database: AppDatabase) {
        let state = State()

        self.state = state
        self.output = Output(state: state)
        self.dependencies = Dependencies(database: database)
    }
}

extension ThemeStyleModel {
    struct Dependencies {
        let database: AppDatabase
    }

    func closedHint(_ screen: SettingsScreen) -> SettingsScreenFlag {
        .closedHint(screen, in: dependencies.database)
    }
}

public extension ThemeStyleModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public internal(set) var style: ThemeStyle = .standard
        public internal(set) var errorNotice = ErrorNotice()

        var previewBase: ThemeStyle?
    }

    @MainActor
    final class Output {
        let state: State

        public var savedStyle: ThemeStyle {
            state.previewBase ?? state.style
        }

        init(state: State) {
            self.state = state
        }
    }

    func load() async {
        do {
            state.style = try await dependencies.database.style()
        } catch {
            state.errorNotice.show(SettingMessage.loadFailed)
        }
    }

    func choose(_ corner: ThemeCorner) async {
        await choose(corner, at: \.corner, key: .cornerStyle)
    }

    func choose(displayFont font: ThemeFont) async {
        await choose(font, at: \.displayFont, key: .fontStyle)
    }

    func choose(textFont font: ThemeFont) async {
        await choose(font, at: \.textFont, key: .textFontStyle)
    }

    func preview(displayFont font: ThemeFont) {
        preview(font, at: \.displayFont)
    }

    func preview(textFont font: ThemeFont) {
        preview(font, at: \.textFont)
    }

    func cancelPreview() {
        if let previewBase = state.previewBase {
            state.style = previewBase
        }

        state.previewBase = nil
    }

    func choose(_ size: ThemeTextSize) async {
        await choose(size, at: \.textSize, key: .textSize)
    }

    func choose(_ spacing: ThemeRowSpacing) async {
        await choose(spacing, at: \.rowSpacing, key: .rowSpacing)
    }

    func choose(_ shape: ThemeStampShape) async {
        await choose(shape, at: \.stampShape, key: .stampShape)
    }

    func choose(showsTabTitles: Bool) async {
        await choose(showsTabTitles, at: \.showsTabTitles, key: .tabTitles)
    }

    func choose(_ backdrop: ThemeBackdrop) async {
        await choose(backdrop, at: \.backdrop, key: .backdrop)
    }

    func choose(haptics: Bool) async {
        await choose(haptics, at: \.haptics, key: .haptics)
    }

    func choose(decorations: Bool) async {
        await choose(decorations, at: \.decorations, key: .decorations)
    }
}

private extension ThemeStyleModel {
    func choose<Value>(
        _ value: Value,
        at keyPath: WritableKeyPath<ThemeStyle, Value>,
        key: SettingKey<Value>
    ) async {
        let previous = output.savedStyle

        state.previewBase = nil

        state.style[keyPath: keyPath] = value

        await saveSetting(value, for: key, in: dependencies.database) {
            state.style = previous
        }
    }

    func preview<Value>(
        _ value: Value,
        at keyPath: WritableKeyPath<ThemeStyle, Value>
    ) {
        if state.previewBase == nil {
            state.previewBase = state.style
        }

        state.style[keyPath: keyPath] = value
    }
}
