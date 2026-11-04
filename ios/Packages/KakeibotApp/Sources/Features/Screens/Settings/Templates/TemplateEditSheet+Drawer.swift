import Core
import DesignSystem
import Store
import SwiftUI

extension TemplateEditSheet {
    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            VStack(spacing: 12) {
                Keypad(calculator: model.calculator) {
                    closePanel()
                } onKey: { key in
                    model.press(key)
                }
            }

        case .tag:
            tagChooser
                .padding(.bottom, 8)

        case .memo:
            EmptyView()
        }
    }
}

private extension TemplateEditSheet {
    var tagChooser: some View {
        TagLine(
            tagItems,
            selection: model.tagId,
            onSelect: { id in
                model.toggleTag(id)
            },
            onAdd: {
                tagCategory = model.selectedCategory
            }
        )
    }
}

private extension TemplateEditSheet {
    var tagItems: [TagLine<EntryTag.ID>.Item] {
        model.tags.map { TagLine.Item(id: $0.id, name: $0.name) }
    }
}
