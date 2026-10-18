public enum TemplateOrder: String, CaseIterable, Codable, Sendable {
    case manual
    case frequent
    case category
    case amount
    case name
}

public extension TemplateOrder {
    static let frequentDays = 90
}

extension TemplateOrder: Identifiable {
    public var id: Self {
        self
    }
}
