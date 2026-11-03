import Core
import DesignSystem
import Store

extension EntryList {
    func detail(for template: EntryTemplate) -> String {
        detailParts(for: template).rowDetail ?? ""
    }
}
