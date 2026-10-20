import Core
import DesignSystem
import Store
import SwiftUI

public struct ThemeListView: View {
    @State private var model: ThemeListModel
    @State private var editing: EditTarget?

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase
    private let appIcon: AppIconListModel

    public init(
        database: AppDatabase,
        appIcon: AppIconListModel
    ) {
        let model = ThemeListModel(database: database, appIcon: appIcon)
        _model = State(initialValue: model)
        self.database = database
        self.appIcon = appIcon
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    customSection

                    section("ダーク", isLight: false)

                    section("ライト", isLight: true)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .errorBanner(appIcon.errorNotice) {
            appIcon.errorNotice.clear()
        }
        .confirmation(
            isPresented: isSuggestingIcon,
            systemImage: "app.badge",
            title: "アイコンもそろえますか",
            message: suggestionMessage,
            keepTitle: "そのまま",
            confirmTitle: "そろえる",
            role: .suggestion
        ) { [icon = model.suggestedIcon] in
            Task {
                await model.use(icon)
            }
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: model.current)
        .sheet(item: $editing, onDismiss: reload) { target in
            ThemeEditSheet(
                model: ThemeEditModel(
                    database: database,
                    editing: target.theme,
                    base: target.base ?? model.currentPalette
                )
            )
        }
        .task {
            await model.load()
        }
    }
}

private extension ThemeListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("テーマ")
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var customSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("つくったテーマ")

            LazyVGrid(columns: Self.columns, spacing: 18) {
                ForEach(model.customThemes) { theme in
                    customTile(theme)
                }

                newTile
            }
        }
    }

    var newTile: some View {
        Button {
            editing = .new(base: nil)
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Palette.outline, style: .dashed)
                    .frame(height: 132)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.sans(.headline, weight: .light))
                            .foregroundStyle(Palette.accent)
                    }
                    .padding(4)

                Text("つくる")
                    .font(.footnote)
                    .foregroundStyle(Palette.accent)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func section(
        _ title: String,
        isLight: Bool
    ) -> some View {
        let presets = ThemePreset.allCases.filter { preset in
            preset.palette.isLight == isLight
        }

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)

            LazyVGrid(columns: Self.columns, spacing: 18) {
                ForEach(presets, id: \.self) { preset in
                    VStack(spacing: 8) {
                        previewButton(.preset(preset), palette: preset.palette)

                        tileTitle(
                            preset.title,
                            isCurrent: isCurrent(.preset(preset))
                        )
                    }
                }
            }
        }
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
            .tracking(3)
            .foregroundStyle(Palette.accent)
            .padding(.leading, 6)
    }

    func customTile(_ theme: Theme) -> some View {
        VStack(spacing: 8) {
            previewButton(.custom(theme.id), palette: theme.palette)

            Button {
                editing = .edit(theme)
            } label: {
                HStack(spacing: 4) {
                    tileTitle(
                        theme.name,
                        isCurrent: isCurrent(.custom(theme.id))
                    )

                    Image(systemName: "pencil")
                        .font(.caption2)
                        .foregroundStyle(Palette.accent)
                }
                .frame(minHeight: 28)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    func previewButton(
        _ choice: ThemeChoice,
        palette: ThemePalette
    ) -> some View {
        let isCurrent = isCurrent(choice)
        let ring = isCurrent ? Palette.accent : Color.clear

        return Button {
            Task {
                await model.select(choice)
            }
        } label: {
            ThemePreview(palette: palette)
                .padding(4)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(ring, lineWidth: 2)
                }
                .overlay(alignment: .bottomTrailing) {
                    if isCurrent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Palette.accent, Palette.background)
                            .offset(x: 6, y: 6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.3), value: isCurrent)
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("これをもとにつくる", systemImage: "plus.square.on.square") {
                editing = .new(base: palette)
            }
        }
    }

    func tileTitle(
        _ title: String,
        isCurrent: Bool
    ) -> some View {
        let color = isCurrent ? Palette.accentStrong : Palette.subtext

        return Text(title)
            .font(.footnote)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

private extension ThemeListView {
    enum EditTarget: Identifiable {
        case new(base: ThemePalette?)
        case edit(Theme)

        var id: String {
            switch self {
            case .new: "new"
            case let .edit(theme): theme.id.description
            }
        }

        var theme: Theme? {
            switch self {
            case .new: nil
            case let .edit(theme): theme
            }
        }

        var base: ThemePalette? {
            switch self {
            case let .new(base): base
            case .edit: nil
            }
        }
    }

    var isSuggestingIcon: Binding<Bool> {
        Binding {
            model.suggestedIcon != nil
        } set: { isShown in
            if !isShown {
                model.dismissSuggestion()
            }
        }
    }

    var suggestionMessage: String {
        let title = model.suggestedIcon?.title ?? ""
        return "アプリアイコンも\(title)にできます"
    }

    func isCurrent(_ choice: ThemeChoice) -> Bool {
        choice == model.current
    }

    func reload() {
        Task {
            await model.load()
        }
    }
}

private extension ThemeListView {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )
}
