import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateShelfSheet: View {
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
            VStack(spacing: 14) {
                header

                CapsulePicker(
                    selection: $model.templateType,
                    options: Self.typeOptions
                )

                searchField

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(sections) { section in
                            sectionView(section)
                        }

                        if sections.isEmpty {
                            Text(emptyText)
                                .font(.footnote)
                                .foregroundStyle(Palette.mist)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                Rectangle()
                    .fill(Palette.night)
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isEditing) {
                TemplateListView(database: database)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private extension TemplateShelfSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            Text("テンプレート")
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            RingButton(systemImage: "slider.horizontal.3", label: "編集") {
                isSearching = false
                isEditing = true
            }
        }
    }

    var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.sans(.small, weight: .light))
                .foregroundStyle(Palette.mist)

            TextField(
                "名前で探す",
                text: $query,
                prompt: Text("名前で探す").foregroundStyle(Palette.dusk)
            )
            .font(.subheadline)
            .foregroundStyle(Palette.ink)
            .tint(Palette.gold)
            .submitLabel(.search)
            .focused($isSearching)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Palette.drawer, in: Capsule())
        .overlay {
            Capsule()
                .stroke(searchStroke, lineWidth: 1)
        }
        .animation(.snappy(duration: 0.2), value: isSearching)
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

private extension TemplateShelfSheet {
    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    var sections: [HomeModel.TemplateSection] {
        model.templateSections(matching: query)
    }

    var emptyText: String {
        query.isEmpty
            ? "まだテンプレートがありません"
            : "「\(query)」に合うテンプレートはありません"
    }

    var searchStroke: Color {
        isSearching ? Palette.gold : Palette.gold.opacity(.muted)
    }

    func use(_ template: EntryTemplate) {
        isSearching = false
        onUse(template)
    }
}
