import Foundation

public struct Theme: Hashable, Sendable {
    public let id: ID

    public var name: String
    public var background: String
    public var surface: String
    public var textPrimary: String
    public var textSecondary: String
    public var accent: String
    public var expense: String
    public var income: String
    public var cornerRadius: Int
    public var fontId: String
    public var isBuiltin: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        name: String,
        background: String,
        surface: String,
        textPrimary: String,
        textSecondary: String,
        accent: String,
        expense: String,
        income: String,
        cornerRadius: Int,
        fontId: String,
        isBuiltin: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.background = background
        self.surface = surface
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.accent = accent
        self.expense = expense
        self.income = income
        self.cornerRadius = cornerRadius
        self.fontId = fontId
        self.isBuiltin = isBuiltin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Theme {
    typealias ID = Identifier<Theme>
}

extension Theme: Identifiable {}

extension Theme: Codable {}

public extension Theme {
    var palette: ThemePalette {
        ThemeDraft(self).palette ?? .night
    }
}
