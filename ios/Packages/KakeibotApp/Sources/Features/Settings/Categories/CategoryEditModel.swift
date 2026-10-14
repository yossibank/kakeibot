import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class CategoryEditModel {
    public var name = ""
    public var markKind: MarkKind = .glyph
    public var glyph: Icon.Glyph = .other
    public var color = CategoryEditModel.colors[0]

    public private(set) var emoji = ""
    public private(set) var text = ""
    public private(set) var isHidden = false
    public private(set) var errorMessage: String?

    public let kind: EntryCategory.Kind

    private let database: AppDatabase
    private let editingId: EntryCategory.ID?

    public init(
        database: AppDatabase,
        kind: EntryCategory.Kind,
        editing id: EntryCategory.ID? = nil
    ) {
        self.database = database
        self.kind = kind
        self.editingId = id
    }
}

public extension CategoryEditModel {
    enum MarkKind: Hashable, CaseIterable, Sendable {
        case glyph
        case emoji
        case text
    }

    struct GlyphSection: Identifiable {
        public let title: String
        public let glyphs: [Icon.Glyph]

        public var id: String {
            title
        }
    }

    static let colors = [
        "#E07A5F", "#F4A261", "#F2CC8F", "#E9C46A",
        "#C9A465", "#B08968", "#81B29A", "#6CBF84",
        "#2A9D8F", "#5FA8D3", "#4A6FA5", "#3D5A80",
        "#577590", "#9C6ADE", "#E5989B", "#8D99AE"
    ]

    static let emojiSuggestions = [
        "🍙", "🍜", "☕️", "🍺", "🛒", "🚃", "🚕", "✈️",
        "🏠", "💡", "📱", "🎮", "🎬", "📚", "💊", "🐶"
    ]

    static let glyphSections = [
        GlyphSection(
            title: "食べる",
            glyphs: [.food, .cafe, .cake, .grocery, .fish, .takeout, .social]
        ),
        GlyphSection(
            title: "暮らし",
            glyphs: [
                .daily, .cart, .bag, .home, .sofa, .tools, .laundry,
                .utility, .light, .water, .gas, .phone, .wifi, .laptop,
                .tv
            ]
        ),
        GlyphSection(
            title: "移動",
            glyphs: [
                .transit, .bus, .car, .bicycle, .airplane, .fuel,
                .parking, .travel
            ]
        ),
        GlyphSection(
            title: "楽しむ",
            glyphs: [
                .hobby, .movie, .music, .ticket, .camera, .sports,
                .fitness, .beach, .mountain, .tent, .theater, .art,
                .book, .star
            ]
        ),
        GlyphSection(
            title: "からだ",
            glyphs: [
                .beauty, .haircut, .clothes, .shoe, .medical, .pill,
                .health
            ]
        ),
        GlyphSection(
            title: "家族",
            glyphs: [.baby, .family, .pet, .school, .plant, .flower]
        ),
        GlyphSection(
            title: "お金",
            glyphs: [
                .salary, .bonus, .cash, .bank, .card, .banknote, .coin,
                .invest, .insurance, .tax, .work, .office
            ]
        ),
        GlyphSection(
            title: "ほか",
            glyphs: [.mail, .calendar, .umbrella, .other]
        )
    ]

    var isEditing: Bool {
        editingId != nil
    }

    var draft: CategoryDraft {
        CategoryDraft(kind: kind, name: name, mark: mark, color: color)
    }

    var canSave: Bool {
        draft.problems.isEmpty
    }

    var preview: Icon {
        let date = Date(timeIntervalSince1970: 0)

        return Icon(
            emoji: markKind == .emoji ? emoji : nil,
            text: markKind == .text ? text : nil,
            glyph: markKind == .glyph ? glyph : nil,
            color: color,
            createdAt: date,
            updatedAt: date
        )
    }

    func inputEmoji(_ value: String) {
        let last = value.last { Self.isEmoji($0) }
        emoji = last.map(String.init) ?? ""
    }

    func inputText(_ value: String) {
        text = String(value.prefix(CategoryDraft.maxTextLength))
    }

    func load() async {
        guard let editingId else {
            return
        }

        do {
            let list = try await database.categoryList()
            let category = list.categories.first { $0.id == editingId }

            guard let category, let icon = list.icons[category.iconId] else {
                errorMessage = Self.loadFailedMessage
                return
            }

            apply(CategoryDraft(category, icon: icon))
            isHidden = category.archivedAt != nil
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func save() async -> Bool {
        do {
            try await database.saveCategory(
                draft,
                editing: editingId,
                at: Date()
            )

            return true
        } catch {
            errorMessage = Self.saveFailedMessage
            return false
        }
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.setCategoryHidden(
                editingId,
                isHidden: isHidden,
                at: Date()
            )

            self.isHidden = isHidden
            return true
        } catch {
            errorMessage = Self.saveFailedMessage
            return false
        }
    }
}

private extension CategoryEditModel {
    static let loadFailedMessage = "カテゴリを読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

    var mark: CategoryDraft.Mark {
        switch markKind {
        case .glyph: .glyph(glyph)
        case .emoji: .emoji(emoji)
        case .text: .text(text)
        }
    }

    static func isEmoji(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars

        guard let first = scalars.first else {
            return false
        }

        return first.properties.isEmojiPresentation
            || (first.properties.isEmoji && scalars.count > 1)
    }

    func apply(_ draft: CategoryDraft) {
        name = draft.name
        color = draft.color

        switch draft.mark {
        case let .glyph(glyph):
            markKind = .glyph
            self.glyph = glyph
        case let .emoji(emoji):
            markKind = .emoji
            self.emoji = emoji
        case let .text(text):
            markKind = .text
            self.text = text
        }
    }
}
