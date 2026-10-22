import Core
import DesignSystem
import SwiftUI

public struct BuddyView: View {
    @State private var model: BuddyModel

    @FocusState private var focus: Field?

    public init(model: BuddyModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 18) {
            SettingsBackHeader("キャラクター")

            ScrollView {
                VStack(spacing: 18) {
                    preview

                    if let buddy = model.buddy {
                        SettingsField(
                            "名前（空なら「\(buddy.defaultName)」）",
                            text: $model.customName,
                            focus: $focus,
                            field: .name
                        )
                    }

                    LazyVGrid(columns: Self.columns, spacing: 12) {
                        ForEach(Buddy.allCases, id: \.self) { buddy in
                            option(buddy)
                        }

                        option(nil)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
                .onTapGesture {
                    focus = nil
                }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: model.buddy)
        .onChange(of: model.customName) {
            Task {
                await model.saveName()
            }
        }
        .task {
            await model.load()
        }
    }
}

private extension BuddyView {
    enum Field: Hashable {
        case name
    }

    @ViewBuilder
    var preview: some View {
        if let buddy = model.buddy {
            BuddyBubble(
                buddy,
                name: model.profile.name,
                line: Self.greeting
            )
            .padding(.vertical, 6)
        } else {
            Text("ホームなどにキャラクターを出しません")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .frame(maxWidth: .infinity, minHeight: 72)
        }
    }

    func option(_ buddy: Buddy?) -> some View {
        BuddyOption(
            buddy: buddy,
            isSelected: model.buddy == buddy
        ) {
            focus = nil

            Task {
                await model.choose(buddy)
            }
        }
    }
}

private extension BuddyView {
    static let greeting = BuddyLine(
        mood: .smile,
        text: "予算の残りや、ごほうびの達成でひとこと話します"
    )
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )
}
