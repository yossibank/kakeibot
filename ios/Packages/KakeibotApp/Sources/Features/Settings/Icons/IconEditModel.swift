import Core
import Foundation
import Observation

@MainActor
@Observable
public final class IconEditModel {
    public var markKind: MarkKind = .glyph
    public var glyph: Icon.Glyph
    public var color: String

    public private(set) var emoji = ""
    public private(set) var text = ""

    public init(
        glyph: Icon.Glyph,
        color: String = IconEditModel.colors[0]
    ) {
        self.glyph = glyph
        self.color = color
    }
}

public extension IconEditModel {
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

    struct EmojiSection: Identifiable {
        public let title: String
        public let emojis: [String]

        public var id: String {
            title
        }
    }

    static let colors = [
        "#E07A5F", "#E76F51", "#F28482", "#F4A261",
        "#F6BD60", "#F2CC8F", "#E9C46A", "#C9A465",
        "#B08968", "#9C6644", "#D4C5A9", "#A3B18A",
        "#81B29A", "#6CBF84", "#52B788", "#2A9D8F",
        "#84A98C", "#48CAE4", "#5FA8D3", "#4A6FA5",
        "#3D5A80", "#577590", "#1D3557", "#7B6CF6",
        "#9C6ADE", "#C08497", "#B5838D", "#E5989B",
        "#FFAFCC", "#ADB5BD", "#8D99AE", "#6C757D"
    ]

    static let emojiSections = [
        EmojiSection(
            title: "食べ物",
            emojis: [
                "🍙", "🍣", "🍜", "🍛", "🍝", "🍔", "🍕", "🍞",
                "🥗", "🍱", "🍰", "🍩", "🍎", "🥩", "🥚", "🍪",
                "🍤", "🍢", "🍡", "🥟", "🍳", "🧀", "🍇", "🍓",
                "🍌", "🥐", "🍦", "🍫"
            ]
        ),
        EmojiSection(
            title: "飲み物",
            emojis: [
                "☕️", "🍵", "🧋", "🥤", "🍺", "🍷", "🍶", "🍹",
                "🥛", "🧃", "🍸", "🥂", "🧉", "🫖"
            ]
        ),
        EmojiSection(
            title: "暮らし",
            emojis: [
                "🏠", "🛒", "🧻", "🧴", "🧹", "🛁", "💡", "💧",
                "🔥", "📦", "🧺", "🪴", "🛋️", "🔑", "🧼", "🪥",
                "🧽", "🪑", "🛏️", "🚿", "🔌", "📺"
            ]
        ),
        EmojiSection(
            title: "乗り物",
            emojis: [
                "🚃", "🚌", "🚕", "🚗", "🚲", "✈️", "⛽️", "🚢",
                "🛵", "🅿️", "🚄", "🚇", "🛻", "🛳️", "🚁", "🏍️"
            ]
        ),
        EmojiSection(
            title: "遊び",
            emojis: [
                "🎮", "🎬", "🎤", "🎵", "🎨", "📚", "🎯", "🎳",
                "⚽️", "⛳️", "🎢", "🎁", "🎉", "🏕️", "♨️", "📷",
                "🎸", "🎹", "🎲", "🧩", "🎟️", "🏀", "🎾", "🏊",
                "🎿", "🎣", "🎪", "🏖️"
            ]
        ),
        EmojiSection(
            title: "からだ",
            emojis: [
                "💊", "🏥", "🦷", "💇", "💄", "👕", "👟", "👜",
                "💅", "🧖", "🩺", "🩹", "💉", "👓", "🕶️", "👗",
                "👠", "🧢"
            ]
        ),
        EmojiSection(
            title: "人と動物",
            emojis: [
                "👶", "🧒", "👪", "🐶", "🐱", "🐟", "🐦", "🌸",
                "👫", "👨‍👩‍👧", "🧸", "🐰", "🐹", "🐢", "🦜", "🌳",
                "🌻"
            ]
        ),
        EmojiSection(
            title: "お金",
            emojis: [
                "💰", "💴", "💳", "🏦", "📈", "🧾", "💼", "🏢",
                "🎫", "✉️", "📱", "💻", "💵", "🪙", "📉", "🏧",
                "📝", "📮", "🧧", "💎"
            ]
        ),
        EmojiSection(
            title: "季節と記号",
            emojis: [
                "🎂", "🎄", "🎍", "🌙", "☀️", "⭐️", "❤️", "✨",
                "🔔", "📅", "🎀", "🏆"
            ]
        )
    ]

    static let glyphSections = [
        GlyphSection(
            title: "食べる",
            glyphs: [
                .food, .cafe, .drink, .cake, .snack, .grocery, .fish, .cooking,
                .takeout, .bottle, .social, .dining, .hotdrink, .oven,
                .microwave, .stove
            ]
        ),
        GlyphSection(
            title: "暮らし",
            glyphs: [
                .daily, .cart, .bag, .store, .delivery, .home, .bed, .sofa,
                .bath, .toilet, .laundry, .cleaning, .trash, .fridge, .lamp,
                .light, .utility, .water, .gas, .key, .lock, .tools, .repair,
                .battery, .dishwasher, .aircon, .fan, .heater, .faucet, .plug,
                .door, .chair, .floorlamp, .pipe, .apartment, .bathtub
            ]
        ),
        GlyphSection(
            title: "機械",
            glyphs: [
                .phone, .wifi, .laptop, .computer, .tv, .audio, .printer,
                .display, .keyboard, .video, .antenna, .media
            ]
        ),
        GlyphSection(
            title: "移動",
            glyphs: [
                .transit, .train, .bus, .car, .ev, .bicycle, .scooter,
                .motorcycle, .airplane, .ferry, .boat, .fuel, .parking,
                .highway, .walk, .map, .travel, .carpool, .truck, .ropeway,
                .subway, .signpost, .charger, .luggage, .flight
            ]
        ),
        GlyphSection(
            title: "楽しむ",
            glyphs: [
                .hobby, .movie, .music, .karaoke, .guitar, .ticket, .party,
                .balloon, .camera, .photo, .paint, .art, .theater, .book, .news,
                .magazine, .puzzle, .dice, .star, .trophy, .notes, .piano,
                .books, .fireworks, .dance, .crown, .laurel, .giftbox
            ]
        ),
        GlyphSection(
            title: "運動と外出",
            glyphs: [
                .sports, .fitness, .yoga, .swim, .soccer, .baseball, .tennis,
                .beach, .mountain, .tent, .binoculars, .court, .ski, .hiking,
                .golf, .fishing, .basketball, .football, .volleyball,
                .skateboard, .surfing, .race, .medal, .training
            ]
        ),
        GlyphSection(
            title: "からだ",
            glyphs: [
                .beauty, .haircut, .comb, .glasses, .clothes, .hanger, .shoe,
                .handbag, .medical, .pill, .syringe, .bandage, .mask, .health,
                .hospital, .checkup, .drip, .hearing, .eye, .sunglasses
            ]
        ),
        GlyphSection(
            title: "人と動物",
            glyphs: [
                .baby, .toy, .family, .parent, .friends, .person, .pet, .dog,
                .cat, .bird, .rabbit, .tortoise, .school, .plant, .tree,
                .flower, .couple, .group, .backpack, .pencil, .stationery,
                .desk, .lizard, .insect, .ladybug
            ]
        ),
        GlyphSection(
            title: "お金",
            glyphs: [
                .salary, .bonus, .cash, .bank, .card, .banknote, .coin, .invest,
                .budget, .stats, .discount, .insurance, .tax, .contract,
                .subscription, .work, .office, .goal, .target, .loss,
                .walletPass, .barcode, .qrcode, .donation, .security, .document,
                .clipboard, .tag
            ]
        ),
        GlyphSection(
            title: "ほか",
            glyphs: [
                .mail, .calendar, .clock, .hourglass, .bell, .bookmark, .clip,
                .sun, .moon, .rain, .snow, .umbrella, .globe, .question, .other,
                .cloud, .temperature, .wind, .sparkle, .like, .smile, .infinity,
                .number
            ]
        )
    ]

    var mark: IconDraft.Mark {
        switch markKind {
        case .glyph: .glyph(glyph)
        case .emoji: .emoji(emoji)
        case .text: .text(text)
        }
    }

    var draft: IconDraft {
        IconDraft(mark: mark, color: color)
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
        text = String(value.prefix(IconDraft.maxTextLength))
    }

    func apply(_ icon: Icon) {
        apply(IconDraft(icon))
    }

    func apply(_ draft: IconDraft) {
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

private extension IconEditModel {
    static func isEmoji(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars

        guard let first = scalars.first else {
            return false
        }

        return first.properties.isEmojiPresentation
            || (first.properties.isEmoji && scalars.count > 1)
    }
}
