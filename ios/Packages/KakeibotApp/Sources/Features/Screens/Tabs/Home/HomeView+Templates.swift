import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension HomeView {
    var templateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeTemplateHeaderLayout(spacing: 8) {
                SectionTitle("テンプレート")

                CapsulePicker(
                    selection: Bindable(model.state).fields.templateType,
                    options: Self.typeOptions,
                    size: .small
                )

                Button("すべて", action: onShowAllTemplates)
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
            }
            .padding(.top, 8)

            if model.output.templates.isEmpty {
                AddButton("テンプレートを作る", action: onAddTemplate)
            } else {
                templateTools

                templateShelf
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
    }
}

private extension HomeView {
    var templateTools: some View {
        HStack(spacing: 8) {
            Text("押すとすぐ記録")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            Spacer()

            if model.output.templates.count > 1 {
                HomeTemplateOrderButton(
                    title: model.input.templateOrder.title,
                    onOpen: onOpenOrderMenu
                )
                .layoutPriority(1)
            }

            ToolButton(systemImage: "plus", action: onAddTemplate)
        }
    }

    var templateShelf: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(shelfRows.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        ForEach(shelfRows[index]) { template in
                            CappedWidthLayout(maxWidth: shelfCardWidth) {
                                templateButton(template)
                            }
                        }
                    }
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            layout.shelfWidth = width - Self.shelfMargin * 2
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, Self.shelfMargin, for: .scrollContent)
        .contentMargins(.vertical, 8, for: .scrollContent)
        .scrollClipDisabled()
        .mask {
            Rectangle()
                .padding(.vertical, -Self.shadowRoom)
        }
        .padding(.horizontal, -Self.shelfMargin)
        .padding(.vertical, -8)
    }

    func templateButton(_ template: EntryTemplate) -> some View {
        Button {
            onUseTemplate(template)
        } label: {
            TemplateRowCard(
                icon: model.output.icon(for: template),
                name: template.name,
                detail: model.output.detail(for: template),
                amount: template.amount,
                fit: .hug
            )
        }
        .buttonStyle(.plain)
    }
}

private extension HomeView {
    static let shadowRoom: CGFloat = 32
    static let shelfMargin: CGFloat = 16

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    var shelfRows: [[EntryTemplate]] {
        let templates = model.output.templates

        guard templates.count > 2 else {
            return [templates]
        }

        let indexed = templates.enumerated()
        let top = indexed.filter { $0.offset.isMultiple(of: 2) }.map(\.element)
        let bottom = indexed.filter { !$0.offset.isMultiple(of: 2) }.map(\.element)

        return [top, bottom]
    }

    var shelfCardWidth: CGFloat {
        layout.shelfWidth > 0 ? layout.shelfWidth * 0.85 : .infinity
    }
}
