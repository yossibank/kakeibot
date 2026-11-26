package com.yossibank.kakeibot.featuremodels.screens

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.select
import com.yossibank.kakeibot.featuremodels.screens.entry.model.wallets
import com.yossibank.kakeibot.featuremodels.screens.tabs.assets.model.AssetsModel
import com.yossibank.kakeibot.featuremodels.screens.tabs.home.model.HomeModel
import com.yossibank.kakeibot.featuremodels.screens.tabs.records.model.RecordsModel
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.model.ReviewModel
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.MonthOverview
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import kotlinx.coroutines.launch

class ScreenFlowTabs(
    setup: ModelTestSetup,
) {
    private val round = ObservationRound()

    val home = HomeModel(
        parts = setup.parts,
        today = setup.today,
        round = round,
    )

    val records = RecordsModel(
        parts = setup.parts,
        today = setup.today,
        round = round,
    )

    val review = ReviewModel(
        parts = setup.parts,
        today = setup.today,
        round = round,
    )

    val assets = AssetsModel(
        parts = setup.parts,
        today = setup.today,
        round = round,
    )

    val overview: MonthOverview
        get() = checkNotNull(home.input.overview)

    val lists: List<EntryList?>
        get() = listOf(
            home.input.overview?.list,
            records.input.list,
            review.input.list,
            assets.input.list,
        )

    val amounts: List<List<Int>>
        get() = lists.map { list -> list?.entries.orEmpty().map { it.amount }.sorted() }

    fun setToday(today: LocalDate) {
        home.state.today = today
        records.state.today = today
        review.state.today = today
        assets.setToday(today)
    }

    fun isOn(today: LocalDate): Boolean =
        home.input.overview?.today == today && assets.input.today == today

    fun balance(of: Identifier<Wallet>): Long? {
        val row = assets.output.rows.firstOrNull { it.id == of }
        return row?.balance
    }
}

suspend fun ModelTestSetup.openTabs(): ScreenFlowTabs {
    val tabs = ScreenFlowTabs(this)

    scope.launch { tabs.home.observe() }
    scope.launch { tabs.records.observe() }
    scope.launch { tabs.review.observe() }
    scope.launch { tabs.assets.observe() }
    ModelWait.until { tabs.lists.all { it != null } }

    return tabs
}

suspend fun ModelTestSetup.entryModel(
    editing: Identifier<Entry>? = null,
    today: LocalDate = this.today,
): EntryModel {
    val model = EntryModel(
        parts = parts,
        today = today,
        editing = editing,
    )

    model.load()

    return model
}

suspend fun ModelTestSetup.record(
    amount: Int,
    type: Entry.Kind = Entry.Kind.expense,
    on: LocalDate? = null,
    today: LocalDate = this.today,
    wallet: Identifier<Wallet>? = null,
    memo: String = "",
) {
    val model = entryModel(today = today)

    model.select(type = type)
    model.type(amount)
    model.output.wallets.firstOrNull { it.id == wallet }?.let { model.select(wallet = it) }
    on?.let(model.state::select)
    model.state.update { copy(memo = memo) }

    check(model.save()) { "記録を保存できなかった" }
}

suspend fun ModelTestSetup.passDay(
    to: LocalDate,
    tabs: ScreenFlowTabs,
) {
    database.generateRecurringEntries(through = to, at = now)
    tabs.setToday(to)
}

fun EntryModel.type(amount: Int) {
    for (digit in amount.toString()) {
        state.press(AmountCalculator.Key.Digit(digit.digitToInt()))
    }
}
