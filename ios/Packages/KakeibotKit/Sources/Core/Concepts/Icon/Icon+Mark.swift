public extension Icon {
    enum Mark: Hashable, Sendable {
        case glyph(Glyph)
        case emoji(String)
        case text(String)

        public init(_ icon: Icon) {
            let emoji = icon.emoji ?? ""

            if let glyph = icon.glyph {
                self = .glyph(glyph)
            } else if !emoji.isEmpty {
                self = .emoji(emoji)
            } else {
                self = .text(icon.text ?? "")
            }
        }
    }

    var mark: Mark {
        Mark(self)
    }
}
