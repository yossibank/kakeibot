import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

extension EntryVoiceFlowTests {
    @Test
    func usesTheModelChoiceForCategory() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let category = try #require(model.output.categories.last)
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

        #expect(model.state.category.id == category.id)
    }

    @Test
    func passesOwnWordsAsHints() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let source = FakeVoiceSource()
        let flow = EntryVoiceFlow(dependencies: .fake(source))
        let category = try #require(model.output.categories.first)
        let wallet = try #require(model.output.wallets.first)

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

        #expect(model.output.amount == 990)
        #expect(flow.state.notices.result.current?.text == "ランチ990円")
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
        await waitForHistory(model)

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
        await waitForHistory(model)

        let similar = model.output.voiceExamples(for: "iPhoneの支払い 4800円")
        let recent = model.output.voiceExamples(for: "コーヒー 450円")

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
        let fromVoice = model.output.isDateFromVoice
        model.state.setDate(setup.date)

        #expect(fromVoice)
        #expect(!model.output.isDateFromVoice)
        #expect(model.output.isMemoFromVoice)
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

        #expect(flow.state.presented.step == nil)
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

        #expect(model.output.amount == 980)
        #expect(flow.state.notices.result.current?.outcome == .applied)
    }

    @Test
    func hidesVoiceForTransfers() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = try await loadedModel(setup)
        let expense = model.output.showsVoice

        model.select(.transfer)

        #expect(expense)
        #expect(!model.output.showsVoice)
    }
}
