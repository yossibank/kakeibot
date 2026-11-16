public enum HomeSection: String, CaseIterable, Codable, Identifiable, Sendable {
    case customize
    case budget
    case templates
    case recent
    case bills
    case stamps

    public static let standard: [Self] = [.budget, .customize, .templates, .recent]

    public var id: Self {
        self
    }
}
