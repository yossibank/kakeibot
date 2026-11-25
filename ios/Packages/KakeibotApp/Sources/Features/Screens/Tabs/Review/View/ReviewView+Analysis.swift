import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension ReviewView {
    struct PressButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .brightness(configuration.isPressed ? -0.06 : 0)
                .animation(.snappy(duration: 0.15), value: configuration.isPressed)
        }
    }

    var analysisBanner: some View {
        Button {
            if model.output.hasNewReport {
                model.move(by: -1)
            }

            model.state.sheet = .analysis
        } label: {
            HStack(spacing: 12) {
                Image(systemName: bannerSymbol)
                    .sansFont(.body, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 40, height: 40)
                    .background(
                        Palette.accent.opacity(.subtle),
                        in: .rect(cornerRadius: ReviewReportRadius.block)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(bannerLabel)
                        .textFont(.caption2, weight: .bold)
                        .tracking(2)
                        .foregroundStyle(Palette.accent)

                    Text(bannerTitle)
                        .displayFont(style: .subheadline, weight: .bold)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentTransition(periodTextTransition)
                }

                Spacer(minLength: 8)

                if model.output.hasNewReport {
                    Text("NEW")
                        .sansFont(.micro, weight: .bold)
                        .tracking(1)
                        .foregroundStyle(Palette.backgroundBottom)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Palette.gold, in: Capsule())
                        .fixedSize()
                        .transition(.scale.combined(with: .opacity))
                }

                DisclosureMark(.band)
                    .foregroundStyle(Palette.accent)
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
            .padding(.trailing, 16)
            .background(Palette.card, in: .rect(cornerRadius: ReviewReportRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: ReviewReportRadius.card)
                    .strokeBorder(Palette.accent.opacity(.muted))
            }
            .shadow(color: Palette.accent.opacity(.subtle), radius: 12, y: 6)
            .animation(.smooth, value: model.output.hasNewReport)
            .contentShape(.rect)
        }
        .buttonStyle(PressButtonStyle())
    }

    var analysisSheet: some View {
        VStack(spacing: 12) {
            SheetHeader {
                model.state.sheet = nil
            } title: {
                Text("ふりかえり")
                    .displayFont(.body)
                    .foregroundStyle(Palette.accent)
            }
            .padding(.horizontal, 20)

            PeriodStepper(
                title: periodTitle,
                subtitle: analysisNote,
                currentTitle: model.output.isCurrentPeriod ? nil : currentPeriodTitle,
                transition: periodTextTransition,
                canMoveForward: model.output.canMoveForward,
                onMove: { count in
                    move(by: count)
                },
                onCurrent: moveToCurrentPeriod
            )
            .padding(.horizontal, 16)

            ScrollView {
                sheetContent
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .pageSlide(slide, page: model.output.period)
            }
            .scrollIndicators(.hidden)
            .id(model.output.period.commentKey)
            .onPageSwipe(following: $slide, canMove: canMove) { direction in
                move(direction)
            }
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: model.output.period.commentKey) {
            await model.loadGoals()
        }
        .task(id: model.output.reasonTrigger) {
            await model.refreshReason()
        }
        .task(id: model.output.noteTrigger) {
            await model.refreshNotes()
        }
        .sheet(item: Bindable(model.state).analysisShare) { share in
            shareSheet(share)
        }
        .backdrop()
        .presentationSizing(.tallForm)
    }
}

private extension ReviewView {
    @ViewBuilder
    var sheetContent: some View {
        if model.output.isCurrentPeriod {
            progressView
        } else {
            ReviewClosingView(
                content: model.output.closingContent,
                goals: model.output.closingGoals,
                notes: model.output.closingNotes,
                name: analysisName,
                previousName: model.output.period.previous.displayName,
                unit: model.input.scale.unitName,
                onOpenGoal: { item in
                    model.state.analysisShare = model.output.goalShare(of: item)
                },
                onOpenWhy: { row, why in
                    model.state.analysisShare = model.output.whyShare(of: row, why: why)
                }
            )
            .task(id: model.output.period) {
                await model.markReportSeen()
            }
        }
    }

    var progressView: some View {
        let period = model.output.period
        let closingDate = period.range.upperBound.adding(days: 1)
        let previousTitle = "\(period.previous.displayName)のふりかえりを見る"
        let daysLeft = model.state.today.days(until: closingDate)

        return ReviewProgressView(
            pace: model.output.pace,
            year: model.output.yearProgress,
            unit: model.input.scale.unitName,
            currentName: currentName,
            goals: model.output.goalItems,
            closingTitle: "\(analysisName)のふりかえり",
            closingDate: closingDate,
            closingDaysLeft: daysLeft,
            nextGoalTitle: "\(period.adding(1).displayName)の一手",
            previousTitle: previousTitle,
            onOpenPrevious: {
                move(by: -1)
            },
            onOpenMonth: { month in
                model.state.analysisShare = model.output.monthShare(of: month)
            }
        )
    }
}

private extension ReviewView {
    var bannerSymbol: String {
        model.output.isCurrentPeriod && !model.output.hasNewReport
            ? "chart.bar.xaxis"
            : "envelope.open"
    }

    var bannerLabel: String {
        model.output.isCurrentPeriod && !model.output.hasNewReport
            ? "途中経過"
            : "締めのレポート"
    }

    var bannerTitle: String {
        if model.output.hasNewReport {
            return "\(model.output.period.previous.displayName)のレポートが届きました"
        }

        return model.output.isCurrentPeriod
            ? "\(analysisName)の途中経過を見る"
            : "\(analysisName)のレポートを見る"
    }

    var analysisName: String {
        let month = model.output.period.range.upperBound.yearMonth

        return switch model.input.scale {
        case .week: currentName
        case .month: "\(month.month)月"
        case .year: "\(String(month.year))年"
        }
    }

    var analysisNote: String {
        let span = Self.span(of: model.output.elapsedRange, separator: "〜")
        let count = model.output.entryCount(in: model.output.period.range)
        return "\(span) · \(count) 件の記録"
    }

    var currentName: String {
        let isCurrent = model.output.period.range.contains(model.state.today)

        return switch model.input.scale {
        case .week: isCurrent ? "今週" : "この週"
        case .month: isCurrent ? "今月" : "この月"
        case .year: isCurrent ? "今年" : "この年"
        }
    }

    static func span(
        of range: ClosedRange<LocalDate>,
        separator: String
    ) -> String {
        let start = range.lowerBound
        let end = range.upperBound
        return "\(start.monthDayText)\(separator)\(end.monthDayText)"
    }
}
