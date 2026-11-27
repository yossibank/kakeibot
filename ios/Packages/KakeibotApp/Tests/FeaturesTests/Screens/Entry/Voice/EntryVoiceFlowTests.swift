import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing
import TestSupport

@MainActor
struct EntryVoiceFlowTests {
    @Test
    func appliesSpokenFieldsAndUndoesThem() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let wallet = try #require(model.output.wallets.last)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))
        var applied = 0

        await flow.start(for: model, today: setup.date) {
            applied += 1
        }

        source.say("昨日コンビニで980円、\(wallet.name)で")
        let previewAmount = flow.input.preview?.amount
        await flow.finish()

        #expect(previewAmount == 980)
        #expect(model.output.amount == 980)
        #expect(model.state.payment.date == setup.date.adding(days: -1))
        #expect(model.state.payment.walletId == wallet.id)
        #expect(model.state.fields.store == "コンビニ")
        #expect(model.output.isDateFromVoice)
        #expect(model.output.isWalletFromVoice)
        #expect(model.output.isMemoFromVoice)
        #expect(flow.state.notice?.outcome == .applied)
        #expect(flow.state.notice?.count == 4)
        #expect(flow.state.notice?.title == "声から 4 つ入れました")
        #expect(applied == 1)
        #expect(flow.state.step == nil)
        #expect(source.isFinished)

        flow.undoLast(in: model)

        #expect(model.output.amount == 0)
        #expect(model.state.payment.date == setup.date)
        #expect(model.state.fields.memo.isEmpty)
        #expect(!model.output.isDateFromVoice)
        #expect(flow.state.notice == nil)
    }

    @Test
    func keepsKeypadOpenWhenAmountIsMissing() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))
        var applied = 0

        await flow.start(for: model, today: setup.date) {
            applied += 1
        }

        source.say("昨日のコンビニ")
        await flow.finish()

        #expect(model.output.amount == 0)
        #expect(model.state.payment.date == setup.date.adding(days: -1))
        #expect(flow.state.notice?.outcome == .missingAmount)
        #expect(flow.state.notice?.message == "「昨日のコンビニ」")
        #expect(flow.state.notice?.canUndo == false)
        #expect(applied == 0)
    }

    @Test
    func tellsWhenNothingWasHeard() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let flow = EntryVoiceFlow(dependencies: .fake(FakeVoiceSource()))

        await flow.start(for: model, today: setup.date) {}
        await flow.finish()

        #expect(flow.state.notice?.outcome == .unheard)
        #expect(flow.state.notice?.title == "聞き取れませんでした")
        #expect(flow.state.notice?.message == nil)
    }

    @Test
    func finishesAfterSilence() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))

        await flow.start(for: model, today: setup.date) {}
        source.say("500円")
        await ObservationWait.until { flow.state.step == nil }

        #expect(flow.state.step == nil)
        #expect(model.output.amount == 500)
        #expect(source.isFinished)
    }

    @Test
    func keepsRecentLevelsWhileListening() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))

        await flow.start(for: model, today: setup.date) {}
        source.hear(0.4)
        source.hear(0.8)

        #expect(flow.input.levels.count == EntryVoiceFlow.levelCount)
        #expect(Array(flow.input.levels.prefix(3)) == [0.8, 0.4, 0])

        await flow.cancel()
        source.hear(0.6)

        #expect(flow.input.levels.allSatisfy { $0 == 0 })
    }

    @Test
    func countsSilenceFromTheLastVoice() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let clock = FakeVoiceClock()
        let flow = EntryVoiceFlow(dependencies: .fake(source, clock: clock))

        await flow.start(for: model, today: setup.date) {}

        #expect(flow.state.silence.startedAt == nil)
        #expect(flow.input.silenceDuration == 0.1)

        source.say("500円")
        let first = try #require(flow.state.silence.startedAt)

        clock.advance(by: .milliseconds(20))
        source.hear(0.8)

        #expect(flow.state.silence.startedAt == nil)

        source.say("500円、カードで")
        source.hear(0)
        let second = try #require(flow.state.silence.startedAt)

        #expect(second > first)

        await flow.cancel()

        #expect(flow.state.silence.startedAt == nil)
    }

    @Test
    func finishesWhenSilenceRunsOutBeforeTheWords() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))

        await flow.start(for: model, today: setup.date) {}
        source.hear(0.8)
        source.hear(0)
        let counting = flow.state.silence.startedAt != nil
        await ObservationWait.until { flow.state.step == nil }

        #expect(counting)
        #expect(flow.state.step == nil)
        #expect(source.isFinished)
    }

    @Test
    func keepsListeningWhileTheVoiceIsLoud() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let clock = FakeVoiceClock()
        let flow = EntryVoiceFlow(dependencies: .fake(source, clock: clock))

        await flow.start(for: model, today: setup.date) {}
        source.say("500円")
        let silence = try #require(flow.input.silenceTask)
        await ObservationWait.until { clock.isSleeping }

        for _ in 0..<6 {
            source.hear(0.8)
            clock.advance(by: .milliseconds(40))
        }

        await silence.value

        #expect(flow.state.step == .listening)

        await flow.cancel()
    }

    @Test
    func clearsNoticeAfterAWhile() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))

        await flow.start(for: model, today: setup.date) {}
        source.say("500円")
        await flow.finish()
        let shown = flow.state.notice != nil
        await ObservationWait.until { flow.state.notice == nil }

        #expect(shown)
        #expect(flow.state.notice == nil)
    }

    @Test
    func cancelLeavesTheEntryAsItWas() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))
        var counts: [Int] = []

        await flow.start(for: model, today: setup.date) {}
        counts.append(flow.state.rounds.starts)
        source.say("980円")
        await flow.cancel()
        counts.append(flow.state.rounds.ends)

        #expect(model.output.amount == 0)
        #expect(flow.state.step == nil)
        #expect(flow.state.notice == nil)
        #expect(source.isCancelled)
        #expect(counts == [1, 1])
    }

    @Test
    func showsDeniedCardWhenPermissionWasRefused() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        var dependencies = EntryVoiceFlow.Dependencies.fake(FakeVoiceSource())
        dependencies.requestPermission = { false }
        dependencies.isDenied = { true }
        let flow = EntryVoiceFlow(dependencies: dependencies)

        await flow.start(for: model, today: setup.date) {}
        let step = flow.state.step
        flow.closeDenied()

        #expect(step == .denied)
        #expect(flow.state.step == nil)
        #expect(flow.state.rounds.starts == 0)
    }
}

extension EntryVoiceFlowTests {
    func saveEntry(
        memo: String,
        in setup: EntryModelTests.Setup,
        at seconds: TimeInterval = 1_791_000_000
    ) async throws {
        let options = try await setup.database.entryOptions()
        let walletId = try #require(options.wallets.first?.id)

        let draft = EntryDraft(
            type: .expense,
            amount: 450,
            date: setup.date,
            categoryId: options.expenseCategories.first?.id,
            walletId: walletId,
            memo: memo
        )

        _ = try await setup.database.saveEntry(
            draft,
            at: Date(timeIntervalSince1970: seconds)
        )
    }

    func waitForHistory(_ model: EntryModel) async {
        await ObservationWait.until {
            !model.output.voiceExamples(for: "").isEmpty
        }
    }

    func loadedModel(_ setup: EntryModelTests.Setup) async throws -> EntryModel {
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        return model
    }
}
