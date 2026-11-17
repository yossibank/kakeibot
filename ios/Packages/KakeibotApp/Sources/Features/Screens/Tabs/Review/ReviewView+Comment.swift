import Core
import DesignSystem
import SwiftUI

extension ReviewView {
    struct CommentTrigger: Hashable {
        let key: String
        let input: ReviewInsight.Input?
    }

    var commentTrigger: CommentTrigger {
        CommentTrigger(
            key: model.period.commentKey,
            input: model.list == nil ? nil : model.insightInput
        )
    }

    @ViewBuilder
    var commentCard: some View {
        if model.comment != .hidden {
            ReviewCommentCard(
                state: model.comment,
                title: commentTitle,
                until: model.commentRange.upperBound,
                onRewrite: {
                    Task {
                        await model.refreshComment(rewriting: true)
                    }
                },
                onRecord: {
                    let range = model.period.range
                    let date = range.contains(model.today) ? model.today : range.lowerBound

                    onAddEntry(date)
                },
                onFold: { isFolded in
                    Task {
                        await model.foldComment(isFolded)
                    }
                }
            )
        }
    }
}

private extension ReviewView {
    var commentTitle: String {
        let isCurrent = model.period.range.contains(model.today)

        let name = switch model.scale {
        case .week: isCurrent ? "今週" : "この週"
        case .month: isCurrent ? "今月" : "この月"
        case .year: isCurrent ? "今年" : "この年"
        }

        return "\(name)のひとこと"
    }
}
