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
                if let notice = model.notice {
                    banner(notice)
                        .padding(.horizontal, 16)
                        .padding(.bottom, bottom)
                        .onTapGesture {
                            clear()
                        }
                        .transition(Self.transition)
                }
            }
            .animation(.snappy, value: model.notice)
            .sensoryFeedback(.success, trigger: model.change) { _, new in
                new != nil
            }
            .task(id: model.notice) {
                await clearLater()
            }
    }
}

private extension EntryNoticeBanner {
    @ViewBuilder
    func banner(_ notice: EntryNoticeModel.Notice) -> some View {
        switch notice {
        case .changed:
            NoticeBanner(
                notice.message,
                systemImage: "checkmark",
                actionTitle: "取り消す"
            ) {
                Task {
                    await model.undo()
                }
            }
        case .undone:
            NoticeBanner(
                notice.message,
                systemImage: "arrow.uturn.backward"
            )
        case .undoFailed:
            NoticeBanner(
                notice.message,
                systemImage: "exclamationmark",
                tone: .error
            )
        }
    }
}

private extension EntryNoticeBanner {
    static let transition = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)

    func clear() {
        guard model.notice != nil else {
            return
        }

        model.clear()
    }

    func clearLater() async {
        guard let notice = model.notice else {
            return
        }

        let duration = Duration.seconds(notice.seconds)

        guard await (try? Task.sleep(for: duration)) != nil else {
            return
        }

        model.clear()
    }
}
