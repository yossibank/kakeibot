import Core
import DesignSystem
import SwiftUI

extension HomeView {
    var templateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeTemplateHeaderLayout(spacing: 8) {
                SectionTitle("テンプレート")

                CapsulePicker(
                    selection: $model.templateType,
                    options: Self.typeOptions,
                    size: .small
                )

                Button("すべて", action: onShowAllTemplates)
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
            }
            .padding(.top, 8)

            if model.templates.isEmpty {
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

            if model.templates.count > 1 {
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

                Text(model.templateOrder.title)
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
        let row = GridItem(.fixed(Self.tileHeight), spacing: 12, alignment: .leading)
        let rows = Array(repeating: row, count: shelfRowCount)

        return ScrollView(.horizontal) {
            LazyHGrid(rows: rows, spacing: 12) {
                ForEach(model.templates) { template in
                    CappedWidthLayout(maxWidth: shelfCardWidth) {
                        templateButton(template)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            shelfWidth = width - Self.shelfMargin * 2
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
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
                icon: model.icon(for: template),
                name: template.name,
                detail: model.detail(for: template),
                amount: template.amount,
                fit: .hug
            )
        }
        .buttonStyle(.plain)
    }
}

private extension HomeView {
    static let tileHeight = TemplateRowCard.Fit.hug.height
    static let shadowRoom: CGFloat = 32
    static let shelfMargin: CGFloat = 16
    static let toolStroke = Palette.accent.opacity(.muted)

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    var shelfRowCount: Int {
        model.templates.count > 2 ? 2 : 1
    }

    var shelfCardWidth: CGFloat {
        shelfWidth > 0 ? shelfWidth * 0.85 : .infinity
    }
}
