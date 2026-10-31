import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class ThemeStyleModel {
    public private(set) var style: ThemeStyle = .standard

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    private var previewBase: ThemeStyle?

    public init(database: AppDatabase) {
        self.database = database
    }
}

extension ThemeStyleModel {
    func closedHint(_ screen: SettingsScreen) -> SettingsScreenFlag {
        .closedHint(screen, in: database)
    }
}

public extension ThemeStyleModel {
    var savedStyle: ThemeStyle {
        previewBase ?? style
    }

    func load() async {
        do {
            style = try await database.style()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
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
        if let previewBase {
            style = previewBase
        }

        previewBase = nil
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
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"

    func choose<Value>(
        _ value: Value,
        at keyPath: WritableKeyPath<ThemeStyle, Value>,
        key: SettingKey<Value>
    ) async {
        let previous = previewBase ?? style

        previewBase = nil

        style[keyPath: keyPath] = value

        do {
            try await database.setSetting(key, to: value)
        } catch {
            style = previous
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func preview<Value>(
        _ value: Value,
        at keyPath: WritableKeyPath<ThemeStyle, Value>
    ) {
        if previewBase == nil {
            previewBase = style
        }

        style[keyPath: keyPath] = value
    }
}
