import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class ThemeStyleModel: SettingSaving {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(database: AppDatabase) {
        let state = State()
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
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
        public internal(set) var errorNotice = ErrorNotice()

        public private(set) var preview: ThemeStyle?

        func show<Value>(
            _ value: Value,
            at keyPath: WritableKeyPath<ThemeStyle, Value>,
            over saved: ThemeStyle
        ) {
            var style = preview ?? saved

            style[keyPath: keyPath] = value
            preview = style
        }

        func clearPreview() {
            preview = nil
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var style: ThemeStyle = .standard
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        public var style: ThemeStyle {
            state.preview ?? input.style
        }

        public var savedStyle: ThemeStyle {
            input.style
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    func load() async {
        do {
            input.style = try await dependencies.database.style()
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
        state.clearPreview()
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
        let previous = input.style
        var chosen = output.style

        chosen[keyPath: keyPath] = value

        state.clearPreview()
        input.style = chosen

        await saveSetting(value, for: key, in: dependencies.database) {
            input.style = previous
        }
    }

    func preview<Value>(
        _ value: Value,
        at keyPath: WritableKeyPath<ThemeStyle, Value>
    ) {
        state.show(value, at: keyPath, over: input.style)
    }
}
