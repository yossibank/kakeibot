import Core
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
        let previewAmount = flow.preview?.amount
        await flow.finish()

        #expect(previewAmount == 980)
        #expect(model.output.amount == 980)
        #expect(model.state.payment.date == setup.date.adding(days: -1))
        #expect(model.state.payment.walletId == wallet.id)
        #expect(model.state.store == "コンビニ")
        #expect(model.output.isDateFromVoice)
        #expect(model.output.isWalletFromVoice)
        #expect(model.output.isMemoFromVoice)
        #expect(flow.notice?.outcome == .applied)
        #expect(flow.notice?.count == 4)
        #expect(flow.notice?.title == "声から 4 つ入れました")
        #expect(applied == 1)
        #expect(flow.step == nil)
        #expect(source.isFinished)

        flow.undoLast(in: model)

        #expect(model.output.amount == 0)
        #expect(model.state.payment.date == setup.date)
        #expect(model.state.memo.isEmpty)
        #expect(!model.output.isDateFromVoice)
        #expect(flow.notice == nil)
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
        #expect(flow.notice?.outcome == .missingAmount)
        #expect(flow.notice?.message == "「昨日のコンビニ」")
        #expect(flow.notice?.canUndo == false)
        #expect(applied == 0)
    }

    @Test
    func tellsWhenNothingWasHeard() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let flow = EntryVoiceFlow(dependencies: .fake(FakeVoiceSource()))

        await flow.start(for: model, today: setup.date) {}
        await flow.finish()

        #expect(flow.notice?.outcome == .unheard)
        #expect(flow.notice?.title == "聞き取れませんでした")
        #expect(flow.notice?.message == nil)
    }

    @Test
    func finishesAfterSilence() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))

        await flow.start(for: model, today: setup.date) {}
        source.say("500円")
        await ObservationWait.until { flow.step == nil }

        #expect(flow.step == nil)
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

        #expect(flow.levels.count == EntryVoiceFlow.levelCount)
        #expect(Array(flow.levels.prefix(3)) == [0.8, 0.4, 0])

        await flow.cancel()
        source.hear(0.6)

        #expect(flow.levels.allSatisfy { $0 == 0 })
    }

    @Test
    func countsSilenceFromTheLastVoice() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))

        await flow.start(for: model, today: setup.date) {}

        #expect(flow.silenceStart == nil)
        #expect(flow.silenceDuration == 0.1)

        source.say("500円")
        let first = try #require(flow.silenceStart)

        try await Task.sleep(for: .milliseconds(20))
        source.hear(0.8)

        #expect(flow.silenceStart == nil)

        source.say("500円、カードで")
        source.hear(0)
        let second = try #require(flow.silenceStart)

        #expect(second > first)

        await flow.cancel()

        #expect(flow.silenceStart == nil)
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
        let counting = flow.silenceStart != nil
        await ObservationWait.until { flow.step == nil }

        #expect(counting)
        #expect(flow.step == nil)
        #expect(source.isFinished)
    }

    @Test
    func keepsListeningWhileTheVoiceIsLoud() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))

        await flow.start(for: model, today: setup.date) {}
        source.say("500円")

        for _ in 0..<6 {
            source.hear(0.8)
            try await Task.sleep(for: .milliseconds(40))
        }

        #expect(flow.step == .listening)

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
        let shown = flow.notice != nil
        await ObservationWait.until { flow.notice == nil }

        #expect(shown)
        #expect(flow.notice == nil)
    }

    @Test
    func cancelLeavesTheEntryAsItWas() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))
        var counts: [Int] = []

        await flow.start(for: model, today: setup.date) {}
        counts.append(flow.startCount)
        source.say("980円")
        await flow.cancel()
        counts.append(flow.endCount)

        #expect(model.output.amount == 0)
        #expect(flow.step == nil)
        #expect(flow.notice == nil)
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
        let step = flow.step
        flow.closeDenied()

        #expect(step == .denied)
        #expect(flow.step == nil)
        #expect(flow.startCount == 0)
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

    func waitForHistory(_ model: EntryModel) async throws {
        for _ in 0..<50 where model.output.voiceExamples(for: "").isEmpty {
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    func loadedModel(_ setup: EntryModelTests.Setup) async throws -> EntryModel {
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()
        return model
    }
}
