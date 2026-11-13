import Core
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct EntryVoiceFlowTests {
    @Test
    func appliesSpokenFieldsAndUndoesThem() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let wallet = try #require(model.wallets.last)
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
        #expect(model.amount == 980)
        #expect(model.date == setup.date.adding(days: -1))
        #expect(model.walletId == wallet.id)
        #expect(model.store == "コンビニ")
        #expect(model.isDateFromVoice)
        #expect(model.isWalletFromVoice)
        #expect(model.isMemoFromVoice)
        #expect(flow.notice?.outcome == .applied)
        #expect(flow.notice?.count == 4)
        #expect(flow.notice?.title == "声から 4 つ入れました")
        #expect(applied == 1)
        #expect(flow.step == nil)
        #expect(source.isFinished)

        flow.undoLast(in: model)

        #expect(model.amount == 0)
        #expect(model.date == setup.date)
        #expect(model.memo.isEmpty)
        #expect(!model.isDateFromVoice)
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

        #expect(model.amount == 0)
        #expect(model.date == setup.date.adding(days: -1))
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
        try await Task.sleep(for: .milliseconds(300))

        #expect(flow.step == nil)
        #expect(model.amount == 500)
        #expect(source.isFinished)
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
        try await Task.sleep(for: .milliseconds(300))

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

        #expect(model.amount == 0)
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

    @Test
    func usesTheModelChoiceForCategory() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let category = try #require(model.categories.last)
        var dependencies = EntryVoiceFlow.Dependencies.fake(FakeVoiceSource())
        let source = FakeVoiceSource()
        dependencies.makeSource = { source }
        dependencies.choose = { question in
            VoiceReading.Choice(categoryIndex: question.categories.count - 1, walletIndex: nil)
        }
        let flow = EntryVoiceFlow(dependencies: dependencies)

        await flow.start(for: model, today: setup.date) {}
        source.say("1200円")
        await flow.finish()

        #expect(model.categoryId == category.id)
    }

    @Test
    func passesOwnWordsAsHints() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))
        let category = try #require(model.categories.first)
        let wallet = try #require(model.wallets.first)

        await flow.start(for: model, today: setup.date) {}

        #expect(source.hints.contains(category.name))
        #expect(source.hints.contains(wallet.name))
        #expect(Set(source.hints).count == source.hints.count)
    }

    @Test
    func readsTheAmountFromAnAlternative() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))

        await flow.start(for: model, today: setup.date) {}
        source.say("ランチ休憩", alternatives: ["ランチ990円"])
        await flow.finish()

        #expect(model.amount == 990)
        #expect(flow.notice?.text == "ランチ990円")
    }

    @Test
    func asksTheModelWithRecentExamples() async throws {
        let setup = try await EntryModelTests.Setup()
        try await saveEntry(memo: "スタバ", in: setup)
        let model = try await loadedModel(setup)
        let observing = Task {
            await model.observeHistory()
        }
        defer {
            observing.cancel()
        }
        try await waitForHistory(model)

        var dependencies = EntryVoiceFlow.Dependencies.fake(FakeVoiceSource())
        let source = FakeVoiceSource()
        var asked: EntryVoiceQuestion?
        dependencies.makeSource = { source }
        dependencies.choose = { question in
            asked = question
            return nil
        }
        let flow = EntryVoiceFlow(dependencies: dependencies)

        await flow.start(for: model, today: setup.date) {}
        source.say("スタバ 450円")
        await flow.finish()

        #expect(asked?.text == "スタバ 450円")
        #expect(asked?.examples.first?.hasPrefix("スタバ → カテゴリ：") == true)
    }

    @Test
    func putsSimilarEntriesFirstInExamples() async throws {
        let setup = try await EntryModelTests.Setup()
        try await saveEntry(memo: "iPhone", in: setup, at: 1_791_000_000)

        for index in 0..<10 {
            try await saveEntry(memo: "ランチ\(index)", in: setup, at: 1_791_000_100 + Double(index))
        }

        let model = try await loadedModel(setup)
        let observing = Task {
            await model.observeHistory()
        }
        defer {
            observing.cancel()
        }
        try await waitForHistory(model)

        let similar = model.voiceExamples(for: "iPhoneの支払い 4800円")
        let recent = model.voiceExamples(for: "コーヒー 450円")

        #expect(similar.first?.hasPrefix("iPhone → カテゴリ：") == true)
        #expect(similar.count == 8)
        #expect(recent.first?.hasPrefix("ランチ9 → カテゴリ：") == true)
        #expect(!recent.contains { $0.hasPrefix("iPhone") })
    }

    @Test
    func dropsUnderlineWhenTheFieldChanges() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)

        model.apply(VoiceReading(amount: 300, date: setup.date.adding(days: -1), memo: "本屋"))
        let fromVoice = model.isDateFromVoice
        model.date = setup.date

        #expect(fromVoice)
        #expect(!model.isDateFromVoice)
        #expect(model.isMemoFromVoice)
    }

    @Test
    func cancelWhileStartingStopsTheSource() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))
        source.holdsStart = true

        let starting = Task {
            await flow.start(for: model, today: setup.date) {}
        }

        for _ in 0..<100 where !source.isHolding {
            await Task.yield()
        }

        await flow.cancel()
        source.releaseStart()
        await starting.value

        #expect(flow.step == nil)
        #expect(source.log.last == "cancel")
    }

    @Test
    func readsTheLastResultGivenWhileFinishing() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))
        source.finalTranscript = EntryVoiceTranscript(
            settled: "コンビニで",
            alternatives: ["コンビニで980円"]
        )

        await flow.start(for: model, today: setup.date) {}
        source.say("コンビニで")
        await flow.finish()

        #expect(model.amount == 980)
        #expect(flow.notice?.outcome == .applied)
    }

    @Test
    func hidesVoiceForTransfers() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let expense = model.showsVoice

        model.select(.transfer)

        #expect(expense)
        #expect(!model.showsVoice)
    }
}

private extension EntryVoiceFlowTests {
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
        for _ in 0..<50 where model.voiceExamples(for: "").isEmpty {
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    func loadedModel(_ setup: EntryModelTests.Setup) async throws -> EntryModel {
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        return model
    }
}

@MainActor
private final class FakeVoiceSource: EntryVoiceSource {
    private(set) var isFinished = false
    private(set) var isCancelled = false
    private(set) var hints: [String] = []
    private(set) var log: [String] = []

    var holdsStart = false
    var finalTranscript: EntryVoiceTranscript?

    private var onEvent: (@MainActor (EntryVoiceEvent) -> Void)?
    private var startGate: CheckedContinuation<Void, Never>?

    var isHolding: Bool {
        startGate != nil
    }

    func start(
        hints: [String],
        _ onEvent: @escaping @MainActor (EntryVoiceEvent) -> Void
    ) async throws {
        self.hints = hints
        self.onEvent = onEvent

        if holdsStart {
            await withCheckedContinuation { continuation in
                startGate = continuation
            }
        }

        log.append("start")
    }

    func finish() async {
        if let finalTranscript {
            onEvent?(.transcript(finalTranscript))
        }

        isFinished = true
        log.append("finish")
    }

    func cancel() async {
        isCancelled = true
        log.append("cancel")
    }

    func releaseStart() {
        startGate?.resume()
        startGate = nil
    }

    func say(
        _ text: String,
        alternatives: [String] = []
    ) {
        onEvent?(.transcript(EntryVoiceTranscript(settled: text, alternatives: alternatives)))
    }
}

private extension EntryVoiceFlow.Dependencies {
    @MainActor
    static func fake(_ source: FakeVoiceSource) -> Self {
        Self(
            isAvailable: { true },
            isDenied: { false },
            requestPermission: { true },
            makeSource: { source },
            prepare: {},
            choose: { _ in nil },
            silence: .milliseconds(100),
            noticeDuration: .milliseconds(100)
        )
    }
}
