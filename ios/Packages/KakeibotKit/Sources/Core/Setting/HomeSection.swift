public enum HomeSection: String, CaseIterable, Codable, Sendable {
    case budget
    case templates
    case recent
}

extension HomeSection: Identifiable {
    public var id: Self {
        self
    }
}
