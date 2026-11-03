import Core
import DesignSystem
import Store
import SwiftUI

public struct HomeTemplateShelfSheet: View {
    @Bindable private var model: HomeModel

    @State private var query = ""
    @State private var isEditing = false

    @FocusState private var isSearching: Bool

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase
    private let onUse: (EntryTemplate) -> Void

    public init(
        model: HomeModel,
        database: AppDatabase,
        onUse: @escaping (EntryTemplate) -> Void
    ) {
        self.model = model
        self.database = database
        self.onUse = onUse
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                CapsulePicker(
                    selection: $model.templateType,
                    options: Self.typeOptions
                )

                SearchField(
                    "名前で探す",
                    text: $query,
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
            .background {
                Backdrop()
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isEditing) {
                TemplateListView(database: database)
            }
        }
    }
}

private extension HomeTemplateShelfSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            SheetTitle("テンプレート")

            Spacer()

            RingButton(systemImage: "slider.horizontal.3", label: "編集") {
                isSearching = false
                isEditing = true
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
                        icon: model.icon(for: template),
                        name: template.name,
                        detail: model.detail(for: template),
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

    var sections: [HomeModel.TemplateSection] {
        model.templateSections(matching: query)
    }

    var emptyText: String {
        query.isEmpty ? "まだテンプレートがありません" : "「\(query)」に合うテンプレートはありません"
    }

    func use(_ template: EntryTemplate) {
        isSearching = false
        onUse(template)
    }
}
