public enum TemplateOrder: String, CaseIterable, Codable, Sendable {
    case manual
    case frequent
    case category
    case amount
    case name
}

extension TemplateOrder: Identifiable {
    public var id: Self {
        self
    }
}
