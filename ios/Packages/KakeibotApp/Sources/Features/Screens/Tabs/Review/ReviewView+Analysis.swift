import Core
import DesignSystem
import SwiftUI

extension ReviewView {
    struct CommentTrigger: Hashable {
        let key: String
        let input: ReviewInsight.Input?
        let breakdown: ReviewBreakdown.Input?
    }

    var commentTrigger: CommentTrigger {
        CommentTrigger(
            key: model.period.commentKey,
            input: model.list == nil ? nil : model.insightInput,
            breakdown: model.breakdownInput
        )
    }

    var showsAnalysis: Bool {
        model.comment != .hidden && model.display == .analysis
    }

    var analysisView: some View {
        ReviewAnalysisView(
            state: model.comment,
            note: analysisNote,
            unit: model.scale.unitName,
            currentName: currentName,
            onRewrite: {
                Task {
                    await model.refreshComment(rewriting: true)
                }
            },
            onRecord: {
                let range = model.period.range
                let date = range.contains(model.today) ? model.today : range.lowerBound

                onAddEntry(date)
            }
        )
    }

    @ViewBuilder
    var displaySwitch: some View {
        if model.comment != .hidden {
            ReviewDisplaySwitch(
                display: model.display,
                state: model.comment,
                onSelect: { display in
                    model.display = display
                }
            )
        }
    }
}

private extension ReviewView {
    var analysisNote: String {
        let range = model.commentRange
        let start = range.lowerBound
        let end = range.upperBound
        let span = "\(start.yearMonth.month)/\(start.day)–\(end.yearMonth.month)/\(end.day)"
        return "\(span) · \(model.commentEntryCount) 件"
    }

    var currentName: String {
        let isCurrent = model.period.range.contains(model.today)

        return switch model.scale {
        case .week: isCurrent ? "今週" : "この週"
        case .month: isCurrent ? "今月" : "この月"
        case .year: isCurrent ? "今年" : "この年"
        }
    }
}
