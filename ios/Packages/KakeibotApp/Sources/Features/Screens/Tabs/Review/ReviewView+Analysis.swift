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

    var analysisBanner: some View {
        Button {
            showsAnalysis = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .sansFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.backgroundBottom)
                    .frame(width: 40, height: 40)
                    .background(Self.bannerIconFill, in: .rect(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "sparkle")
                            .sansFont(.micro, weight: .bold)
                            .foregroundStyle(Palette.backgroundBottom)
                            .offset(x: -4, y: 4)
                    }
                    .shadow(color: Palette.accent.opacity(.muted), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.isCurrentPeriod ? "途中経過" : "AI 分析レポート")
                        .textFont(.caption2, weight: .bold)
                        .tracking(2)
                        .foregroundStyle(Palette.accent)

                    Text(bannerTitle)
                        .textFont(.subheadline, weight: .bold)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentTransition(periodTextTransition)
                }

                Spacer(minLength: 8)

                if model.hasNewAnalysis {
                    Text("NEW")
                        .sansFont(.micro, weight: .bold)
                        .tracking(1)
                        .foregroundStyle(Palette.backgroundBottom)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Palette.accentStrong, in: Capsule())
                        .fixedSize()
                        .transition(.scale.combined(with: .opacity))
                }

                Image(systemName: "chevron.right")
                    .sansFont(.small, weight: .bold)
                    .foregroundStyle(Palette.accent)
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
            .padding(.trailing, 16)
            .background(Self.bannerFill, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Palette.accent.opacity(.medium))
            }
            .shadow(color: Palette.accent.opacity(.subtle), radius: 12, y: 6)
            .animation(.smooth, value: model.hasNewAnalysis)
            .contentShape(.rect)
        }
        .buttonStyle(ReviewAnalysisView.PressButtonStyle())
    }

    var analysisSheet: some View {
        VStack(spacing: 12) {
            HStack {
                RingButton(systemImage: "xmark") {
                    showsAnalysis = false
                }

                Spacer()

                Text("分析レポート")
                    .displayFont(.body)
                    .foregroundStyle(Palette.accent)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
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
        .task(id: commentTrigger) {
            guard !model.isCurrentPeriod else {
                return
            }

            await model.refreshComment()
        }
        .task(id: model.period.commentKey) {
            await model.loadGoals()
        }
        .sheet(item: $analysisShare) { share in
            shareSheet(share)
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .presentationSizing(.tallForm)
    }

    func openAfterAnalysis() {
        guard let pendingRecord else {
            openPendingEntry()
            return
        }

        self.pendingRecord = nil

        onAddEntry(pendingRecord)
    }
}

private extension ReviewView {
    @ViewBuilder
    var sheetContent: some View {
        if model.isCurrentPeriod {
            progressView
        } else {
            analysisView
        }
    }

    var progressView: some View {
        let period = model.period
        let closingDate = period.range.upperBound.adding(days: 1)

        return ReviewProgressView(
            pace: model.pace,
            unit: model.scale.unitName,
            currentName: currentName,
            goals: model.goalItems,
            closingTitle: "\(analysisName)のふりかえり",
            closingDate: closingDate,
            nextGoalTitle: "\(Self.name(of: period.adding(1)))の一手",
            previousTitle: "\(Self.name(of: period.previous))のふりかえりを見る",
            onOpenPrevious: {
                move(by: -1)
            }
        )
    }

    var analysisView: some View {
        ReviewAnalysisView(
            state: model.comment,
            unit: model.scale.unitName,
            currentName: currentName,
            entryCount: model.commentEntryCount,
            focusName: model.breakdownInput?.category,
            months: model.breakdownMonths,
            categories: model.spentCategoryNames,
            previousSpan: previousSpan,
            currentSpan: Self.span(of: model.commentRange, separator: "〜"),
            isNew: model.isWrittenNow,
            onRetry: {
                Task {
                    await model.refreshComment(retrying: true)
                }
            },
            onRecord: {
                let range = model.period.range
                let date = range.contains(model.today) ? model.today : range.lowerBound

                pendingRecord = date
                showsAnalysis = false
            },
            onOpen: { factor in
                analysisShare = model.factorShare(of: factor)
            },
            onOpenCategory: { name in
                analysisShare = model.categoryShare(named: name)
            }
        )
    }
}

private extension ReviewView {
    static var bannerFill: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.muted),
                Palette.accent.opacity(.faint),
                Palette.cardBottom
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var bannerIconFill: RadialGradient {
        RadialGradient(
            colors: [Palette.accentStrong, Palette.accent, Palette.accentDeep],
            center: .topLeading,
            startRadius: 0,
            endRadius: 48
        )
    }

    var bannerTitle: String {
        model.isCurrentPeriod ? "\(analysisName)の途中経過を見る" : "\(analysisName)の分析を見る"
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
        let span = Self.span(of: model.commentRange, separator: "〜")
        return "\(span) · \(model.commentEntryCount) 件の記録"
    }

    var previousSpan: String {
        let range = model.period.comparisonRange(today: model.today)
        return Self.span(of: range, separator: "〜")
    }

    var currentName: String {
        let isCurrent = model.period.range.contains(model.today)

        return switch model.scale {
        case .week: isCurrent ? "今週" : "この週"
        case .month: isCurrent ? "今月" : "この月"
        case .year: isCurrent ? "今年" : "この年"
        }
    }

    static func name(of period: ReviewPeriod) -> String {
        let start = period.range.lowerBound
        let month = period.range.upperBound.yearMonth

        return switch period.scale {
        case .week: "\(start.yearMonth.month)/\(start.day) の週"
        case .month: "\(month.month)月"
        case .year: "\(String(month.year))年"
        }
    }

    static func span(
        of range: ClosedRange<LocalDate>,
        separator: String
    ) -> String {
        let start = range.lowerBound
        let end = range.upperBound
        return "\(start.yearMonth.month)/\(start.day)\(separator)\(end.yearMonth.month)/\(end.day)"
    }
}
