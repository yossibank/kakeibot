enum ReviewEmphasisPart: Hashable {
    case plain(String)
    case name(String)
    case number(String)
}

extension ReviewEmphasisPart {
    static func text(of parts: [Self]) -> String {
        parts.map { part in
            switch part {
            case let .plain(text), let .name(text), let .number(text): text
            }
        }
        .joined()
    }
}
