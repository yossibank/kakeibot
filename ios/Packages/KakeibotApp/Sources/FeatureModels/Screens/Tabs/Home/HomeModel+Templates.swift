import Core
import Foundation
import Store

public extension HomeModel {
    struct TemplateSection: Identifiable {
        public let id: EntryCategory.ID
        public let title: String
        public let templates: [EntryTemplate]
    }
}
