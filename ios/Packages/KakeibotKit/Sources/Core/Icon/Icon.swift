import Foundation

public struct Icon: Hashable, Sendable {
    public let id: ID
    public var emoji: String?
    public var text: String?
    public var glyph: Glyph?
    public var color: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        emoji: String?,
        text: String?,
        glyph: Glyph? = nil,
        color: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.emoji = emoji
        self.text = text
        self.glyph = glyph
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Icon {
    typealias ID = Identifier<Icon>

    enum Glyph: String, CaseIterable, Codable, Sendable {
        case food
        case daily
        case transit
        case social
        case hobby
        case clothes
        case beauty
        case medical
        case home
        case phone
        case utility
        case salary
        case bonus
        case other
        case cash
        case bank
        case cafe
        case cake
        case grocery
        case fish
        case takeout
        case cart
        case bag
        case sofa
        case tools
        case laundry
        case light
        case water
        case gas
        case wifi
        case laptop
        case tv
        case bus
        case car
        case bicycle
        case airplane
        case fuel
        case parking
        case travel
        case movie
        case music
        case ticket
        case camera
        case sports
        case fitness
        case beach
        case mountain
        case tent
        case theater
        case art
        case book
        case star
        case haircut
        case shoe
        case pill
        case health
        case baby
        case family
        case pet
        case school
        case plant
        case flower
        case card
        case banknote
        case coin
        case invest
        case insurance
        case tax
        case work
        case office
        case mail
        case calendar
        case umbrella
        case drink
        case snack
        case cooking
        case bottle
        case bed
        case bath
        case toilet
        case trash
        case key
        case lock
        case lamp
        case fridge
        case cleaning
        case delivery
        case printer
        case audio
        case computer
        case ferry
        case boat
        case scooter
        case motorcycle
        case train
        case highway
        case walk
        case map
        case party
        case balloon
        case puzzle
        case dice
        case guitar
        case paint
        case photo
        case binoculars
        case soccer
        case baseball
        case tennis
        case swim
        case yoga
        case trophy
        case karaoke
        case news
        case magazine
        case glasses
        case comb
        case bandage
        case syringe
        case mask
        case hanger
        case handbag
        case parent
        case toy
        case bird
        case cat
        case dog
        case tortoise
        case rabbit
        case tree
        case friends
        case person
        case discount
        case budget
        case store
        case contract
        case goal
        case target
        case hourglass
        case clock
        case subscription
        case stats
        case sun
        case moon
        case snow
        case rain
        case globe
        case bell
        case bookmark
        case clip
        case repair
        case battery
        case ev
        case question
    }
}

extension Icon: Identifiable {}

extension Icon: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeOrNull(emoji, forKey: .emoji)
        try container.encodeOrNull(text, forKey: .text)
        try container.encodeOrNull(glyph, forKey: .glyph)
        try container.encode(color, forKey: .color)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
