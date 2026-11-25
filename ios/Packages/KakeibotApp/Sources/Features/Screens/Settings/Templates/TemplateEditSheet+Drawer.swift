import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension TemplateEditSheet {
    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            VStack(spacing: 12) {
                Keypad(calculator: model.state.calculator) {
                    closePanel()
                } onKey: { key in
                    model.state.press(key)
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
            selection: model.state.tagId,
            onSelect: { id in
                model.state.toggleTag(id)
            },
            onAdd: {
                model.state.tagCategory = model.output.selectedCategory
            }
        )
    }
}

private extension TemplateEditSheet {
    var tagItems: [TagLine<EntryTag.ID>.Item] {
        model.output.tags.map { TagLine.Item(id: $0.id, name: $0.name) }
    }
}
