import Core
import DesignSystem
import Store
import SwiftUI

public struct ThemeListView: View {
    @State var model: ThemeListModel
    @State var editing: EditTarget?
    @State var menu: Menu?
    @State var pressing: ThemeChoice?
    @State var size: CGSize = .zero
    @State var menuHeight: CGFloat = 0
    @State var proOffer: ProOffer?

    @Environment(\.isPro) var isPro
    @Environment(\.themeStyle.corner) var corner

    @State private var hintFlag: SettingsScreenFlag
    @State private var deletion: Deletion?

    private let database: AppDatabase
    private let appIcon: AppIconListModel

    public init(
        database: AppDatabase,
        appIcon: AppIconListModel
    ) {
        let model = ThemeListModel(database: database, appIcon: appIcon)
        let hintFlag = SettingsScreenFlag.closedHint(.themes, in: database)

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)

        self.database = database
        self.appIcon = appIcon
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: SettingsSpacing.header) {
                SettingsBackHeader("テーマ", hint: hintFlag)

                SettingsIntroCard(
                    systemImage: "paintpalette",
                    headline: ("アプリの色を", "好みに変えられます"),
                    notes: notes,
                    flag: hintFlag
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                        section("ライト", isLight: true)

                        section("ダーク", isLight: false)

                        if !model.customThemes.isEmpty {
                            customSection
                        }

                        systemSection
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .scrollDisabled(menu != nil)
                .deletionNotice($deletion) { deletion in
                    restore(deletion)
                }

                AddButton("テーマを追加", isLocked: !isPro) {
                    create(base: nil)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, SettingsSpacing.top)
            .padding(.bottom, 8)

            if let menu {
                menuLayer(menu)
            }
        }
        .coordinateSpace(.named(Self.space))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            self.size = size
        }
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
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .proOffer(proOffer?.feature) {
            proOffer = nil
        } onUnlock: {
            unlock()
        }
        .haptic(.selection, trigger: model.current)
        .haptic(.impact(weight: .medium), trigger: menu) { _, new in
            new != nil
        }
        .navigationDestination(item: $editing) { target in
            ThemeEditSheet(
                model: ThemeEditModel(
                    database: database,
                    editing: target.theme,
                    base: target.base ?? model.currentPalette
                )
            ) { deletion in
                self.deletion = deletion
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.isSettingsEditPushed, true)
        }
        .onChange(of: editing) { _, editing in
            if editing == nil {
                reload()
            }
        }
        .task {
            await model.load()
        }
    }
}

extension ThemeListView {
    enum ProOffer: Equatable {
        case create(base: ThemePalette?)
        case select(ThemeChoice)

        var feature: String {
            switch self {
            case .create: "テーマを作るの"
            case .select: "作ったテーマ"
            }
        }
    }

    enum EditTarget: Hashable, Identifiable {
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

    static let space = "themes"

    func select(_ choice: ThemeChoice) {
        if case .custom = choice,
           choice != model.current,
           !isPro {
            proOffer = .select(choice)
            return
        }

        Task {
            await model.select(choice)
        }
    }

    func create(base: ThemePalette?) {
        guard isPro else {
            proOffer = .create(base: base)
            return
        }

        editing = .new(base: base)
    }

    func unlock() {
        guard let offer = proOffer else {
            return
        }

        proOffer = nil

        switch offer {
        case let .create(base):
            editing = .new(base: base)
        case let .select(choice):
            Task {
                await model.select(choice)
            }
        }
    }
}

private extension ThemeListView {
    var systemSection: some View {
        let isCurrent = model.current == .system
        let titleColor = isCurrent ? Palette.accentStrong : Palette.subtext

        return VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle("自動")

            LazyVGrid(columns: Self.columns, spacing: 20) {
                Button {
                    select(.system)
                } label: {
                    VStack(spacing: 8) {
                        framed(systemPreview, isCurrent: isCurrent)

                        Text(ThemeChoice.systemTitle)
                            .textFont(.footnote)
                            .foregroundStyle(titleColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var systemPreview: some View {
        ThemePreview(palette: ThemePreset.white.palette)
            .overlay {
                ThemePreview(palette: ThemePreset.black.palette)
                    .mask {
                        HStack(spacing: 0) {
                            Color.clear

                            Color.black
                        }
                    }
            }
    }

    var customSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle("つくったテーマ")

            LazyVGrid(columns: Self.columns, spacing: 20) {
                ForEach(model.customThemes) { theme in
                    tile(
                        .custom(theme.id),
                        palette: theme.palette,
                        title: theme.name,
                        theme: theme
                    )
                }
            }
        }
        .sharesTextScale(id: model.customThemes.map(\.name))
    }

    func section(
        _ title: String,
        isLight: Bool
    ) -> some View {
        let presets = ThemePreset.allCases.filter { preset in
            preset.palette.isLight == isLight
        }

        return VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle(title)

            LazyVGrid(columns: Self.columns, spacing: 20) {
                ForEach(presets, id: \.self) { preset in
                    tile(
                        .preset(preset),
                        palette: preset.palette,
                        title: preset.title,
                        theme: nil
                    )
                }
            }
        }
        .sharesTextScale(id: presets)
    }
}

private extension ThemeListView {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    var notes: [SettingsIntroCard.Note] {
        let select = SettingsIntroCard.Note("hand.tap", "押すと、そのテーマに切り替わります")
        let edit = SettingsIntroCard.Note("square.and.pencil", "つくったテーマは、もう一度押すと編集できます")
        let base = SettingsIntroCard.Note("plus.square.on.square", "長押しで、その色をもとにつくれます")

        return model.customThemes.isEmpty ? [select, base] : [select, edit, base]
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

    func reload() {
        Task {
            await model.load()
        }
    }

    func restore(_ deletion: Deletion) {
        Task {
            await model.restore(deletion)
        }
    }
}
