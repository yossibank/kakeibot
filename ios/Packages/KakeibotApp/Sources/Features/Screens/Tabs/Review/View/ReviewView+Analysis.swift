import Core
import DesignSystem
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
            if model.hasNewReport {
                model.move(by: -1)
            }

            showsAnalysis = true
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

                if model.hasNewReport {
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
            .animation(.smooth, value: model.hasNewReport)
            .contentShape(.rect)
        }
        .buttonStyle(PressButtonStyle())
    }

    var analysisSheet: some View {
        VStack(spacing: 12) {
            SheetHeader {
                showsAnalysis = false
            } title: {
                Text("ふりかえり")
                    .displayFont(.body)
                    .foregroundStyle(Palette.accent)
            }
            .padding(.horizontal, 20)

            PeriodStepper(
                title: periodTitle,
                subtitle: analysisNote,
                currentTitle: model.isCurrentPeriod ? nil : currentPeriodTitle,
                transition: periodTextTransition,
                canMoveForward: model.canMoveForward,
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
                    .pageSlide(slide, page: model.period)
            }
            .scrollIndicators(.hidden)
            .id(model.period.commentKey)
            .onPageSwipe(following: $slide, canMove: canMove) { direction in
                move(direction)
            }
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: model.period.commentKey) {
            await model.loadGoals()
        }
        .task(id: model.reasonTrigger) {
            await model.refreshReason(now: Date())
        }
        .task(id: model.noteTrigger(now: Date())) {
            await model.refreshNotes(now: Date())
        }
        .sheet(item: $analysisShare) { share in
            shareSheet(share)
        }
        .backdrop()
        .presentationSizing(.tallForm)
    }
}

private extension ReviewView {
    @ViewBuilder
    var sheetContent: some View {
        if model.isCurrentPeriod {
            progressView
        } else {
            ReviewClosingView(
                content: model.closingContent,
                goals: model.closingGoals(now: Date()),
                notes: model.closingNotes,
                name: analysisName,
                previousName: model.period.previous.displayName,
                unit: model.scale.unitName,
                onOpenGoal: { item in
                    analysisShare = model.goalShare(of: item)
                },
                onOpenWhy: { row, why in
                    analysisShare = model.whyShare(of: row, why: why)
                }
            )
            .task(id: model.period) {
                await model.markReportSeen()
            }
        }
    }

    var progressView: some View {
        let period = model.period
        let closingDate = period.range.upperBound.adding(days: 1)
        let previousTitle = "\(period.previous.displayName)のふりかえりを見る"
        let daysLeft = model.today.days(until: closingDate)

        return ReviewProgressView(
            pace: model.pace,
            year: model.yearProgress,
            unit: model.scale.unitName,
            currentName: currentName,
            goals: model.goalItems,
            closingTitle: "\(analysisName)のふりかえり",
            closingDate: closingDate,
            closingDaysLeft: daysLeft,
            nextGoalTitle: "\(period.adding(1).displayName)の一手",
            previousTitle: previousTitle,
            onOpenPrevious: {
                move(by: -1)
            },
            onOpenMonth: { month in
                analysisShare = model.monthShare(of: month)
            }
        )
    }
}

private extension ReviewView {
    var bannerSymbol: String {
        model.isCurrentPeriod && !model.hasNewReport
            ? "chart.bar.xaxis"
            : "envelope.open"
    }

    var bannerLabel: String {
        model.isCurrentPeriod && !model.hasNewReport
            ? "途中経過"
            : "締めのレポート"
    }

    var bannerTitle: String {
        if model.hasNewReport {
            return "\(model.period.previous.displayName)のレポートが届きました"
        }

        return model.isCurrentPeriod
            ? "\(analysisName)の途中経過を見る"
            : "\(analysisName)のレポートを見る"
    }

    var analysisName: String {
        let month = model.period.range.upperBound.yearMonth

        return switch model.scale {
        case .week: currentName
        case .month: "\(month.month)月"
        case .year: "\(String(month.year))年"
        }
    }

    var analysisNote: String {
        let span = Self.span(of: model.elapsedRange, separator: "〜")
        let count = model.entryCount(in: model.period.range)
        return "\(span) · \(count) 件の記録"
    }

    var currentName: String {
        let isCurrent = model.period.range.contains(model.today)

        return switch model.scale {
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
