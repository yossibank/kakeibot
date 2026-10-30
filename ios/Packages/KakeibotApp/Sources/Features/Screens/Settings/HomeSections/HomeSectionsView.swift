import Core
import DesignSystem
import Store
import SwiftUI

public struct HomeSectionsView: View {
    @State private var model: HomeSectionsModel
    @State private var dragging: HomeSection?
    @State private var dragStart = 0
    @State private var dragTranslation: CGFloat = 0
    @State private var hintFlag: SettingsScreenFlag

    @Environment(\.themeStyle.corner) private var corner

    public init(
        model: HomeSectionsModel,
        database: AppDatabase
    ) {
        let hintFlag = SettingsScreenFlag.closedHint(.homeSections, in: database)

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("ホームに出すもの", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "rectangle.grid.1x2",
                headline: ("ホームに出すものと", "その順番を選べます"),
                notes: [
                    .init("list.number", "この順でホームに並びます"),
                    .arrange
                ],
                flag: hintFlag
            )

            ScrollView {
                board
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
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.snappy, value: model.layout)
        .transaction(value: model.isLoaded) { transaction in
            transaction.disablesAnimations = true
        }
        .haptic(.selection, trigger: model.layout)
        .task {
            await model.load()
        }
    }
}

private extension HomeSectionsView {
    var board: some View {
        let slots = model.layout.slots

        return VStack(spacing: 0) {
            ForEach(Array(slots.enumerated()), id: \.element) { index, slot in
                switch slot {
                case let .section(section):
                    row(section)
                        .overlay(alignment: .top) {
                            if index > 0,
                               slots[index - 1].section != nil,
                               dragging != section {
                                Hairline()
                                    .padding(.horizontal, 16)
                            }
                        }
                        .offset(y: offset(of: section))
                        .zIndex(layer(of: section))
                case .boundary:
                    boundary
                }
            }
        }
        .background(alignment: .top) {
            zones
        }
    }

    var zones: some View {
        let shownHeight = CGFloat(model.layout.visible.count) * Self.rowHeight
        let hiddenCount = model.layout.order.count - model.layout.visible.count
        let hiddenHeight = CGFloat(hiddenCount + 1) * Self.rowHeight - Self.zoneGap

        return VStack(spacing: Self.zoneGap) {
            Color.clear
                .frame(height: shownHeight)
                .card()

            zoneShape
                .fill(Palette.backgroundBottom.opacity(.strong))
                .overlay {
                    zoneShape
                        .stroke(Palette.subtext.opacity(0.6), style: .dashed)
                }
                .frame(height: hiddenHeight)
        }
    }

    var boundary: some View {
        let isEmpty = model.layout.visible.count == model.layout.order.count
        let title = isEmpty ? "ここへ運ぶと隠せます" : "隠したもの"
        let alignment: Alignment = isEmpty ? .center : .leading

        return HStack(spacing: 8) {
            Image(systemName: "eye.slash")

            Text(title)
        }
        .textFont(.caption)
        .foregroundStyle(Palette.subtext)
        .padding(.horizontal, 16)
        .padding(.top, Self.zoneGap)
        .frame(maxWidth: .infinity, alignment: alignment)
        .frame(height: Self.rowHeight)
    }

    func row(_ section: HomeSection) -> some View {
        let isHidden = model.layout.isHidden(section)
        let opacity = isHidden ? Emphasis.medium.rawValue : 1
        let isDragging = dragging == section
        let scale = isDragging ? Self.liftScale : 1

        return HStack(spacing: 12) {
            HomeSectionThumbnail(section: section)
                .opacity(opacity)

            Text(section.title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(opacity)

            Spacer(minLength: 0)

            Image(systemName: "line.3.horizontal")
                .sansFont(.body)
                .foregroundStyle(Palette.hint)
        }
        .padding(.horizontal, 16)
        .frame(height: Self.rowHeight)
        .background {
            if isDragging {
                zoneShape
                    .fill(Palette.panel)
                    .shadow(color: Palette.shadow, radius: 12, y: 4)
            }
        }
        .scaleEffect(scale)
        .contentShape(.rect)
        .gesture(dragGesture(section))
    }
}

private extension HomeSectionsView {
    static let rowHeight: CGFloat = 56
    static let zoneGap: CGFloat = 16
    static let liftScale: CGFloat = 1.02

    var zoneShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    func offset(of section: HomeSection) -> CGFloat {
        guard
            dragging == section,
            let index = model.layout.slots.firstIndex(of: .section(section))
        else {
            return 0
        }

        return dragTranslation - CGFloat(index - dragStart) * Self.rowHeight
    }

    func layer(of section: HomeSection) -> Double {
        dragging == section ? 1 : 0
    }

    func dragGesture(_ section: HomeSection) -> some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
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

        dragStart = model.layout.slots.firstIndex(of: .section(section)) ?? 0
        dragTranslation = 0

        withAnimation(.snappy) {
            dragging = section
        }
    }

    func moveDragging(
        _ section: HomeSection,
        by translation: CGFloat
    ) {
        let steps = Int((translation / Self.rowHeight).rounded())
        let target = dragStart + steps

        dragTranslation = translation

        withAnimation(.snappy) {
            model.move(section, toSlot: target)
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
            HomeSectionsView(
                model: HomeSectionsModel(database: database),
                database: database
            )
        }
    }
}
