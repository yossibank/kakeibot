import Core
import DesignSystem
import Store
import SwiftUI

public struct ThemeListView: View {
    @State private var model: ThemeListModel
    @State private var hintFlag: SettingsScreenFlag
    @State private var editing: EditTarget?
    @State private var menu: Menu?
    @State private var pressing: ThemeChoice?
    @State private var size: CGSize = .zero
    @State private var menuHeight: CGFloat = 0

    @Environment(\.themeStyle.corner) private var corner

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
            VStack(spacing: 14) {
                SettingsBackHeader("テーマ", hint: hintFlag)

                SettingsHint(
                    flag: hintFlag,
                    lines: Self.hint
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        section("ライト", isLight: true)

                        section("ダーク", isLight: false)

                        customSection

                        systemSection
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .scrollDisabled(menu != nil)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

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
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: model.current)
        .sensoryFeedback(.impact(weight: .medium), trigger: menu) { _, new in
            new != nil
        }
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
    var systemSection: some View {
        let isCurrent = model.current == .system
        let titleColor = isCurrent ? Palette.accentStrong : Palette.subtext

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("自動")

            LazyVGrid(columns: Self.columns, spacing: 18) {
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
            sectionTitle("つくったテーマ")

            LazyVGrid(columns: Self.columns, spacing: 18) {
                ForEach(model.customThemes) { theme in
                    tile(
                        .custom(theme.id),
                        palette: theme.palette,
                        title: theme.name,
                        theme: theme
                    )
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
                RoundedRectangle(cornerRadius: corner.radius(14))
                    .strokeBorder(Palette.outline, style: .dashed)
                    .frame(height: 132)
                    .overlay {
                        Image(systemName: "plus")
                            .sansFont(.headline, weight: .light)
                            .foregroundStyle(Palette.accent)
                    }
                    .padding(4)

                Text("つくる")
                    .textFont(.footnote)
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
                    tile(
                        .preset(preset),
                        palette: preset.palette,
                        title: preset.title,
                        theme: nil
                    )
                }
            }
        }
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .textFont(.caption2)
            .tracking(3)
            .foregroundStyle(Palette.accent)
            .padding(.leading, 6)
    }

    func tile(
        _ choice: ThemeChoice,
        palette: ThemePalette,
        title: String,
        theme: Theme?
    ) -> some View {
        let isCurrent = choice == model.current
        let titleColor = isCurrent ? Palette.accentStrong : Palette.subtext
        let scale: CGFloat = pressing == choice ? 0.94 : 1

        return VStack(spacing: 8) {
            preview(palette, isCurrent: isCurrent)
                .scaleEffect(scale)
                .animation(.snappy(duration: 0.2), value: scale)
                .overlay {
                    GeometryReader { proxy in
                        Color.clear
                            .contentShape(.rect)
                            .onTapGesture {
                                select(choice)
                            }
                            .onLongPressGesture(
                                minimumDuration: Self.menuPressDuration
                            ) {
                                let space = CoordinateSpace.named(Self.space)

                                let menu = Menu(
                                    choice: choice,
                                    palette: palette,
                                    title: title,
                                    theme: theme,
                                    frame: proxy.frame(in: space)
                                )

                                openMenu(menu)
                            } onPressingChanged: { isPressing in
                                pressing = isPressing ? choice : nil
                            }
                    }
                }

            Text(title)
                .textFont(.footnote)
                .foregroundStyle(titleColor)
                .lineLimit(1)
        }
    }

    func preview(
        _ palette: ThemePalette,
        isCurrent: Bool
    ) -> some View {
        framed(ThemePreview(palette: palette), isCurrent: isCurrent)
    }

    func framed(
        _ content: some View,
        isCurrent: Bool
    ) -> some View {
        let ring = isCurrent ? Palette.accent : Color.clear

        return content
            .padding(4)
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(18))
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
    }

    @ViewBuilder
    func menuLayer(_ menu: Menu) -> some View {
        Palette.scrim
            .opacity(0.45)
            .ignoresSafeArea()
            .onTapGesture {
                closeMenu()
            }
            .transition(.opacity)

        preview(menu.palette, isCurrent: menu.choice == model.current)
            .frame(width: menu.frame.width, height: menu.frame.height)
            .scaleEffect(1.04)
            .shadow(color: Palette.glow.opacity(.muted), radius: 12)
            .position(x: menu.frame.midX, y: menu.frame.midY)
            .allowsHitTesting(false)
            .transition(.opacity)

        MenuPanel(width: Self.menuWidth) {
            MenuHeader(menu.title) {
                Circle()
                    .fill(Palette.backgroundTop)
                    .overlay {
                        Circle()
                            .strokeBorder(Palette.accent, lineWidth: 2)
                    }
                    .frame(width: 16, height: 16)
                    .environment(\.palette, menu.palette)
            }

            MenuDivider()

            MenuRow(
                "これをもとにつくる",
                note: "この色から新しくつくります",
                systemImage: "plus.square.on.square"
            ) {
                closeMenu()
                editing = .new(base: menu.palette)
            }

            if let theme = menu.theme {
                MenuDivider()

                MenuRow(
                    "このテーマを編集",
                    systemImage: "square.and.pencil"
                ) {
                    closeMenu()
                    editing = .edit(theme)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            menuHeight = height
        }
        .offset(x: menuX(for: menu), y: menuY(for: menu))
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

private extension ThemeListView {
    struct Menu: Equatable {
        let choice: ThemeChoice
        let palette: ThemePalette
        let title: String
        let theme: Theme?
        let frame: CGRect
    }

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

    func select(_ choice: ThemeChoice) {
        Task {
            await model.select(choice)
        }
    }

    func openMenu(_ menu: Menu) {
        pressing = nil

        withAnimation(.snappy(duration: 0.25)) {
            self.menu = menu
        }
    }

    func closeMenu() {
        withAnimation(.snappy(duration: 0.2)) {
            menu = nil
        }
    }

    func menuX(for menu: Menu) -> CGFloat {
        let preferred = menu.frame.midX - Self.menuWidth / 2
        let limit = size.width - Self.menuWidth - Self.menuInset
        return min(max(preferred, Self.menuInset), limit)
    }

    func menuY(for menu: Menu) -> CGFloat {
        let below = menu.frame.maxY + Self.menuGap
        let fitsBelow = below + menuHeight <= size.height - Self.menuInset

        guard !fitsBelow else {
            return below
        }

        return menu.frame.minY - Self.menuGap - menuHeight
    }

    func reload() {
        Task {
            await model.load()
        }
    }
}

private extension ThemeListView {
    static let space = "themes"
    static let menuWidth: CGFloat = 236
    static let menuInset: CGFloat = 18
    static let menuGap: CGFloat = 10
    static let menuPressDuration = 0.4

    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    static let hint: [SettingsHint.Line] = [
        .init("hand.tap", "押すと、そのテーマに切り替わります"),
        .init("plus.square.on.square", "長押しで、その色をもとにつくれます")
    ]
}
