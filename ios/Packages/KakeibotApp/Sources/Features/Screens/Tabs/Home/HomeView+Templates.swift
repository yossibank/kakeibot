import Core
import DesignSystem
import SwiftUI

extension HomeView {
    var templateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeTemplateHeaderLayout(spacing: 8) {
                SectionTitle("テンプレート")

                CapsulePicker(
                    selection: Bindable(model.state).templateType,
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
                orderButton
                    .layoutPriority(1)
            }

            ToolButton(systemImage: "plus", action: onAddTemplate)
        }
    }

    var orderButton: some View {
        Button {
            onOpenOrderMenu(orderButtonFrame)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .sansFont(.caption, weight: .light)

                Text(model.input.templateOrder.title)
                    .textFont(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .overlay {
                Capsule()
                    .stroke(Self.toolStroke, lineWidth: 1)
            }
            .frame(height: 40)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            orderButtonFrame = frame
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
            shelfWidth = width - Self.shelfMargin * 2
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
    static let toolStroke = Palette.accent.opacity(.muted)

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
        shelfWidth > 0 ? shelfWidth * 0.85 : .infinity
    }
}
