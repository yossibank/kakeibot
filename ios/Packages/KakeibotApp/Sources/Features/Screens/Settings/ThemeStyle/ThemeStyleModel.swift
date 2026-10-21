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

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension ThemeStyleModel {
    func load() async {
        do {
            style = try await database.style()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func choose(_ corner: ThemeCorner) async {
        let previous = style
        style.corner = corner

        do {
            try await database.setSetting(.cornerStyle, to: corner)
        } catch {
            style = previous
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func choose(displayFont font: ThemeFont) async {
        let previous = style
        style.displayFont = font

        do {
            try await database.setSetting(.fontStyle, to: font)
        } catch {
            style = previous
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func choose(textFont font: ThemeFont) async {
        let previous = style
        style.textFont = font

        do {
            try await database.setSetting(.textFontStyle, to: font)
        } catch {
            style = previous
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}

private extension ThemeStyleModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}
