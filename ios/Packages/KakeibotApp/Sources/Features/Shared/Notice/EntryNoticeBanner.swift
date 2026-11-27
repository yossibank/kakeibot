import DesignSystem
import FeatureModels
import SwiftUI

private struct EntryNoticeBanner: ViewModifier {
    let model: EntryNoticeModel
    let inset: CGFloat
    let clearsOnTap: Bool

    func body(content: Content) -> some View {
        let bottom = NoticeBanner.bottomMargin + inset

        return content
            .simultaneousGesture(
                TapGesture().onEnded {
                    model.clearOnTap()
                },
                including: tapMask
            )
            .overlay(alignment: .bottom) {
                if let notice = model.state.notice {
                    banner(notice)
                        .padding(.horizontal, NoticeBanner.sideMargin)
                        .padding(.bottom, bottom)
                        .onTapGesture {
                            model.clearOnTap()
                        }
                        .transition(Self.transition)
                }
            }
            .animation(.snappy, value: model.state.notice)
            .haptic(.success, trigger: model.output.change) { _, new in
                new != nil
            }
    }
}

private extension EntryNoticeBanner {
    @ViewBuilder
    func banner(_ notice: EntryNoticeModel.Notice) -> some View {
        switch notice {
        case let .changed(change) where change.isDeletion:
            EntryDeletionBanner(
                change: change,
                seconds: notice.seconds
            ) {
                model.perform {
                    await $0.undo()
                }
            }
            .id(notice)

        case .changed, .batch:
            NoticeBanner(
                notice.message,
                systemImage: "checkmark",
                actionTitle: "取り消す"
            ) {
                model.perform {
                    await $0.undo()
                }
            }

        case .undone:
            NoticeBanner(
                notice.message,
                systemImage: "arrow.uturn.backward"
            )

        case .failed:
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

    var tapMask: GestureMask {
        clearsOnTap ? .all : .subviews
    }
}

public extension View {
    func entryNotice(
        _ model: EntryNoticeModel,
        above inset: CGFloat,
        clearsOnTap: Bool = true
    ) -> some View {
        modifier(
            EntryNoticeBanner(
                model: model,
                inset: inset,
                clearsOnTap: clearsOnTap
            )
        )
    }
}
