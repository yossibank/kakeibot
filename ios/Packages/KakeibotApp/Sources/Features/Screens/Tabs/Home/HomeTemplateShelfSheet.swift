import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct HomeTemplateShelfSheet: View {
    @Bindable private var model: HomeModel

    @FocusState private var isSearching: Bool

    @Environment(\.dismiss) private var dismiss

    private let parts: ScreenParts
    private let onUse: (EntryTemplate) -> Void

    public init(
        model: HomeModel,
        parts: ScreenParts,
        onUse: @escaping (EntryTemplate) -> Void
    ) {
        self.model = model
        self.parts = parts
        self.onUse = onUse
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                CapsulePicker(
                    selection: Bindable(model.state).fields.templateType,
                    options: Self.typeOptions
                )

                SearchField(
                    "名前で探す",
                    text: Bindable(model.state).fields.shelf.query,
                    focus: $isSearching
                )

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(sections) { section in
                            sectionView(section)
                        }

                        if sections.isEmpty {
                            Text(emptyText)
                                .textFont(.footnote)
                                .foregroundStyle(Palette.subtext)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .padding(.horizontal, -20)
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .backdrop()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: Bindable(model.state).fields.shelf.isEditing) {
                TemplateListView(parts: parts)
            }
        }
        .onDisappear {
            model.state.closeShelf()
        }
    }
}

private extension HomeTemplateShelfSheet {
    var header: some View {
        SheetHeader("テンプレート") {
            dismiss()
        } trailing: {
            RingButton(systemImage: "slider.horizontal.3", label: "編集") {
                isSearching = false
                model.state.fields.shelf.isEditing = true
            }
        }
    }

    func sectionView(_ section: HomeModel.TemplateSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(section.title)

            ForEach(section.templates) { template in
                Button {
                    use(template)
                } label: {
                    TemplateRowCard(
                        icon: model.output.icon(for: template),
                        name: template.name,
                        detail: model.output.detail(for: template),
                        amount: template.amount
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private extension HomeTemplateShelfSheet {
    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    var query: String {
        model.state.fields.shelf.query
    }

    var sections: [HomeModel.TemplateSection] {
        model.output.templateSections(matching: query)
    }

    var emptyText: String {
        query.isEmpty ? "まだテンプレートがありません" : "「\(query)」に合うテンプレートはありません"
    }

    func use(_ template: EntryTemplate) {
        isSearching = false
        onUse(template)
    }
}
