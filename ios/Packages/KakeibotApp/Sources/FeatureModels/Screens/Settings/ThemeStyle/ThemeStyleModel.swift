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

    public init(parts: ScreenParts) {
        let state = State()
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: parts.database)
    }
}

public extension ThemeStyleModel {
    enum FontOffer: Hashable, Sendable {
        case display(ThemeFont)
        case text(ThemeFont)
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public internal(set) var fontOffer: FontOffer?

        public private(set) var preview: ThemeStyle?
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var style: ThemeStyle = .standard
        public internal(set) var openedStyle: ThemeStyle?

        public let textHint = SettingsFoldInput.hint(.themeText)
        public let lookHint = SettingsFoldInput.hint(.themeLook)
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

extension ThemeStyleModel {
    struct Dependencies {
        let database: AppDatabase
    }
}

public extension ThemeStyleModel {
    static func isLocked(
        _ font: ThemeFont,
        isPro: Bool
    ) -> Bool {
        !isPro && !freeFonts.contains(font)
    }

    func load() async {
        do {
            input.style = try await dependencies.database.style()
        } catch {
            state.errorNotice.show(SettingMessage.loadFailed)
        }
    }

    func open(with style: ThemeStyle) {
        if input.openedStyle == nil {
            input.openedStyle = style
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

    func choose(
        _ offer: FontOffer,
        isPro: Bool
    ) async {
        let isLocked = Self.isLocked(offer.font, isPro: isPro)

        guard
            isLocked,
            offer.font != savedFont(for: offer)
        else {
            state.fontOffer = nil
            cancelPreview()
            await save(offer)

            return
        }

        cancelPreview()

        switch offer {
        case let .display(font): preview(displayFont: font)
        case let .text(font): preview(textFont: font)
        }

        state.fontOffer = offer
    }

    func closeFontOffer() {
        state.fontOffer = nil
        cancelPreview()
    }

    func unlockFont() async {
        guard let offer = state.fontOffer else {
            return
        }

        state.fontOffer = nil
        await save(offer)
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
    static let freeFonts: Set<ThemeFont> = [.mincho, .gothic]

    func savedFont(for offer: FontOffer) -> ThemeFont {
        switch offer {
        case .display: input.style.displayFont
        case .text: input.style.textFont
        }
    }

    func save(_ offer: FontOffer) async {
        switch offer {
        case let .display(font): await choose(displayFont: font)
        case let .text(font): await choose(textFont: font)
        }
    }

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

public extension ThemeStyleModel.Output {
    var style: ThemeStyle {
        state.preview ?? input.style
    }

    var savedStyle: ThemeStyle {
        input.style
    }
}

extension ThemeStyleModel.State {
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

public extension ThemeStyleModel.FontOffer {
    var feature: String {
        "\(font.title)の字体"
    }
}

extension ThemeStyleModel.FontOffer {
    var font: ThemeFont {
        switch self {
        case let .display(font), let .text(font): font
        }
    }
}

extension ThemeStyleModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}
