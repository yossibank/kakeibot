import Core
import DesignSystem
import Store
import SwiftUI

public struct HomeSectionsView: View {
    @State private var model: HomeSectionsModel
    @State private var dragging: HomeSection?
    @State private var dragStart = 0
    @State private var dragTranslation: CGFloat = 0

    @Environment(\.themeStyle.corner) private var corner

    public init(model: HomeSectionsModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 20) {
            SettingsBackHeader("ホームに出すもの")

            Text("ホームに並べる順番と、出すものを選べます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 12) {
                    preview
                        .padding(.vertical, 12)

                    VStack(spacing: 0) {
                        ForEach(model.layout.order) { section in
                            row(section)
                                .overlay(alignment: .top) {
                                    if section != model.layout.order.first {
                                        Hairline()
                                    }
                                }
                                .offset(y: offset(of: section))
                                .zIndex(dragging == section ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, 16)
                    .card()

                    Text("≡ を長押しして上下に動かすと並べ替えます")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(dragging != nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.snappy, value: model.layout)
        .transaction(value: model.isLoaded) { transaction in
            transaction.disablesAnimations = true
        }
        .sensoryFeedback(.selection, trigger: model.layout)
        .task {
            await model.load()
        }
    }
}

private extension HomeSectionsView {
    var preview: some View {
        VStack(spacing: 6) {
            HStack {
                Text("ホーム")
                    .displayFont(.caption)
                    .foregroundStyle(Palette.accent)

                Spacer()

                Image(systemName: "gearshape")
                    .sansFont(.caption)
                    .foregroundStyle(Palette.accent)
            }
            .padding(.horizontal, 4)

            ForEach(model.layout.visible) { section in
                previewBlock(section)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: 180, height: 240)
        .background(Palette.background)
        .clipShape(Self.screenShape)
        .overlay {
            Self.screenShape
                .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
        }
        .shadow(color: Palette.shadow.opacity(.muted), radius: 16, y: 6)
    }

    func previewBlock(_ section: HomeSection) -> some View {
        let height = Self.previewHeight(of: section)

        return HStack(spacing: 6) {
            Image(systemName: section.systemImage)
                .sansFont(.micro)

            Text(section.title)
                .textFont(size: .micro)

            Spacer(minLength: 0)
        }
        .foregroundStyle(Palette.accentStrong)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
        .padding(.top, 2)
        .background(Palette.card, in: .rect(cornerRadius: corner.radius(10)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(10))
                .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
        }
    }

    func row(_ section: HomeSection) -> some View {
        let isHidden = model.layout.isHidden(section)
        let opacity = isHidden ? Emphasis.medium.rawValue : 1
        let fill = dragging == section ? Palette.panel : Color.clear

        return HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .sansFont(.body)
                .foregroundStyle(Palette.hint)
                .frame(width: 32, height: Self.rowHeight)
                .contentShape(.rect)
                .gesture(dragGesture(section))

            Text(section.title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(opacity)

            Spacer(minLength: 0)

            CapsulePicker(
                selection: shownBinding(section),
                options: Self.shownOptions
            )
            .disabled(!model.layout.canHide(section))
        }
        .frame(height: Self.rowHeight)
        .background(fill)
    }
}

private extension HomeSectionsView {
    static let rowHeight: CGFloat = 56
    static let screenShape = RoundedRectangle(cornerRadius: 22)

    static let shownOptions: [CapsulePicker<Bool>.Option] = [
        .init("出す", value: true),
        .init("隠す", value: false)
    ]

    static func previewHeight(of section: HomeSection) -> CGFloat {
        switch section {
        case .budget: 64
        case .setup: 32
        case .templates: 40
        case .recent: 48
        }
    }

    func shownBinding(_ section: HomeSection) -> Binding<Bool> {
        Binding {
            !model.layout.isHidden(section)
        } set: { isShown in
            Task {
                await model.setHidden(section, !isShown)
            }
        }
    }

    func offset(of section: HomeSection) -> CGFloat {
        guard
            dragging == section,
            let index = model.layout.order.firstIndex(of: section)
        else {
            return 0
        }

        return dragTranslation - CGFloat(index - dragStart) * Self.rowHeight
    }

    func dragGesture(_ section: HomeSection) -> some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture())
            .onChanged { value in
                switch value {
                case .first(true):
                    startDragging(section)
                case let .second(true, drag?):
                    startDragging(section)
                    moveDragging(section, by: drag.translation.height)
                default:
                    break
                }
            }
            .onEnded { _ in
                finishDragging()
            }
    }

    func startDragging(_ section: HomeSection) {
        guard dragging == nil else {
            return
        }

        dragStart = model.layout.order.firstIndex(of: section) ?? 0
        dragTranslation = 0
        dragging = section
    }

    func moveDragging(
        _ section: HomeSection,
        by translation: CGFloat
    ) {
        let steps = Int((translation / Self.rowHeight).rounded())
        let target = dragStart + steps

        dragTranslation = translation

        withAnimation(.snappy) {
            model.move(section, to: target)
        }
    }

    func finishDragging() {
        guard dragging != nil else {
            return
        }

        withAnimation(.snappy) {
            dragging = nil
            dragTranslation = 0
        }

        Task {
            await model.save()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            HomeSectionsView(model: HomeSectionsModel(database: database))
        }
    }
}
