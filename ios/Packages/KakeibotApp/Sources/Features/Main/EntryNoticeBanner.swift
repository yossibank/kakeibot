import DesignSystem
import SwiftUI

extension View {
    func entryNotice(
        _ model: EntryNoticeModel,
        above inset: CGFloat
    ) -> some View {
        modifier(EntryNoticeBanner(model: model, inset: inset))
    }
}

private struct EntryNoticeBanner: ViewModifier {
    let model: EntryNoticeModel
    let inset: CGFloat

    func body(content: Content) -> some View {
        let bottom = 12 + inset

        return content
            .simultaneousGesture(
                TapGesture().onEnded {
                    clear()
                }
            )
            .overlay(alignment: .bottom) {
                banner
                    .padding(.horizontal, 16)
                    .padding(.bottom, bottom)
            }
            .animation(.snappy, value: model.change)
            .animation(.snappy, value: model.errorMessage)
            .sensoryFeedback(.success, trigger: model.change) { _, new in
                new != nil
            }
            .task(id: model.change) {
                await clearLater()
            }
            .task(id: model.errorMessage) {
                await clearLater()
            }
    }
}

private extension EntryNoticeBanner {
    @ViewBuilder
    var banner: some View {
        if let change = model.change {
            NoticeBanner(
                change.message,
                systemImage: "checkmark",
                actionTitle: "取り消す"
            ) {
                Task {
                    await model.undo()
                }
            }
            .onTapGesture {
                clear()
            }
            .transition(Self.transition)
        } else if let errorMessage = model.errorMessage {
            NoticeBanner(
                errorMessage,
                systemImage: "exclamationmark",
                tone: .error
            )
            .onTapGesture {
                clear()
            }
            .transition(Self.transition)
        }
    }
}

private extension EntryNoticeBanner {
    static let transition = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)

    func clear() {
        guard model.isShown else {
            return
        }

        model.clear()
    }

    func clearLater() async {
        guard model.isShown else {
            return
        }

        guard await (try? Task.sleep(for: .seconds(4))) != nil else {
            return
        }

        model.clear()
    }
}
