public enum DraftProblem: String, CaseIterable, Codable, Error, Sendable {
    case emptyName
    case emptyAmount
    case emptyMark
    case textTooLong
    case invalidColor
    case nameTooLong
    case unreadableColors
}
