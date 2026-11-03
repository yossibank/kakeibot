public enum TemplateOrder: String, CaseIterable, Codable, Identifiable, Sendable {
    case manual
    case frequent
    case category
    case amount
    case name

    public static let frequentDays = 90

    public var id: Self {
        self
    }
}
