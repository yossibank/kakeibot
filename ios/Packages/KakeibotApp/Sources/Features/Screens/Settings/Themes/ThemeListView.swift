import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct ThemeListView: View {
    @State var model: ThemeListModel
    @State var layout = Layout()

    @Environment(\.isPro) var isPro
    @Environment(\.themeStyle.corner) var corner

    private let parts: ScreenParts
    private let appIcon: AppIconListModel

    public init(
        parts: ScreenParts,
        appIcon: AppIconListModel
    ) {
        let model = ThemeListModel(parts: parts, appIcon: appIcon)

        _model = State(initialValue: model)

        self.parts = parts
        self.appIcon = appIcon
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            listColumn

            if let shownMenu {
                menuLayer(shownMenu)
            }
        }
        .coordinateSpace(.named(Self.space))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            layout.size = size
        }
        .errorBanner(model.state.notices.error)
        .errorBanner(appIcon.state.notices.error)
        .confirmation(
            isPresented: isSuggestingIcon,
            systemImage: "app.badge",
            title: "アイコンもそろえますか",
            message: suggestionMessage,
            keepTitle: "そのまま",
            confirmTitle: "そろえる",
            role: .suggestion
        ) { [icon = model.state.presented.suggestedIcon] in
            model.perform {
                await $0.use(icon)
            }
        }
        .backdrop()
        .toolbar(.hidden, for: .navigationBar)
        .proOffer(offer?.feature) {
            model.state.close(offer.map { .offer($0) })
        } onUnlock: {
            unlock()
        }
        .haptic(.selection, trigger: model.input.current)
        .haptic(
            .impact(weight: .medium),
            trigger: model.state.presented.overlay.current?.menu
        ) { _, new in
            new != nil
        }
        .navigationDestination(item: editing) { target in
            editSheet(target)
        }
        .onChange(of: model.state.presented.overlay.current?.editing) { _, editing in
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
    struct Layout {
        var size: CGSize = .zero
        var menuHeight: CGFloat = 0
        var menuFrame: CGRect = .zero
    }
}

extension ThemeListView {
    static let space = "themes"

    var offer: ThemeListModel.Offer? {
        model.state.presented.overlay.current?.offer
    }

    func select(_ choice: ThemeChoice) {
        model.perform { [isPro] in
            await $0.choose(choice, isPro: isPro)
        }
    }

    func create(base: ThemePalette?) {
        model.create(base: base, isPro: isPro)
    }

    func edit(_ theme: Theme) {
        model.state.present(.editing(.edit(theme)))
    }

    func unlock() {
        model.perform {
            await $0.unlock()
        }
    }
}

private extension ThemeListView {
    var listColumn: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("テーマ", hint: hint)

            SettingsIntroCard(
                systemImage: "paintpalette",
                headline: ("アプリの色を", "好みに変えられます"),
                notes: notes,
                hint: hint
            )

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    section("ライト", isLight: true)

                    section("ダーク", isLight: false)

                    if !model.input.customThemes.isEmpty {
                        customSection
                    }

                    systemSection
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(shownMenu != nil)
            .deletionNotice(model.state.notices.deletion) { deletion in
                restore(deletion)
            }

            AddButton("テーマを追加", isLocked: !isPro) {
                create(base: nil)
            }
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
    }

    var systemSection: some View {
        let isCurrent = model.input.current == .system
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
                ForEach(model.input.customThemes) { theme in
                    tile(
                        .custom(theme.id),
                        palette: theme.palette,
                        title: theme.name,
                        theme: theme
                    )
                }
            }
        }
        .sharesTextScale(id: model.input.customThemes.map(\.name))
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

    func editSheet(_ target: ThemeListModel.EditTarget) -> some View {
        ThemeEditSheet(
            model: ThemeEditModel(
                parts: parts,
                editing: target.theme,
                base: target.base ?? model.output.currentPalette
            )
        ) { deletion in
            model.receive(deletion)
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.isSettingsEditPushed, true)
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
        return model.input.customThemes.isEmpty ? [select, base] : [select, edit, base]
    }

    var editing: Binding<ThemeListModel.EditTarget?> {
        Binding {
            model.state.presented.overlay.current?.editing
        } set: { target in
            if target == nil {
                let editing = model.state.presented.overlay.current?.editing
                model.state.close(editing.map { .editing($0) })
            }
        }
    }

    var shownMenu: Menu? {
        guard let choice = model.state.presented.overlay.current?.menu else {
            return nil
        }

        return Menu(
            choice: choice,
            palette: model.output.palette(of: choice),
            title: choice.title(in: model.input.customThemes),
            theme: model.output.theme(of: choice),
            frame: layout.menuFrame
        )
    }

    var isSuggestingIcon: Binding<Bool> {
        Binding {
            model.state.presented.suggestedIcon != nil
        } set: { isShown in
            if !isShown {
                model.dismissSuggestion()
            }
        }
    }

    var suggestionMessage: String {
        let title = model.state.presented.suggestedIcon?.title ?? ""
        return "アプリアイコンも\(title)にできます"
    }

    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
    }

    func reload() {
        model.perform {
            await $0.load()
        }
    }

    func restore(_ deletion: Deletion) {
        model.perform {
            await $0.restore(deletion)
        }
    }
}
