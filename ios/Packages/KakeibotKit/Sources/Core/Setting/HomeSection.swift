public enum HomeSection: String, CaseIterable, Codable, Sendable {
    case customize
    case budget
    case templates
    case recent
    case bills
    case stamps

    public static let standard: [Self] = [.budget, .customize, .templates, .recent]
}

extension HomeSection: Identifiable {
    public var id: Self {
        self
    }
}
