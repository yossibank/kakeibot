public enum HomeSection: String, CaseIterable, Codable, Sendable {
    case customize
    case budget
    case templates
    case recent
    case bills
    case stamps

    public static let standard: [Self] = [.customize, .budget, .templates, .recent]
}

extension HomeSection: Identifiable {
    public var id: Self {
        self
    }
}
