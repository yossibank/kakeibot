public enum HomeSection: String, CaseIterable, Codable, Sendable {
    case budget
    case setup
    case templates
    case recent
}

extension HomeSection: Identifiable {
    public var id: Self {
        self
    }
}
