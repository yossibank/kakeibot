package com.yossibank.kakeibot.featuremodels.screens.tabs.assets.model

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Holdings
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.isDebt
import com.yossibank.kakeibot.core.concepts.wallet.role
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.store.queries.types.EntryList
import kotlinx.coroutines.flow.Flow

class AssetsModel(
    entryList: Flow<EntryList>,
    today: LocalDate,
) {
    val state = State()
    val input = Input(today)
    val output = Output(input)

    private val dependencies = Dependencies(entryList)

    data class Row(
        val id: Identifier<Wallet>,
        val icon: Icon?,
        val name: String,
        val kind: Wallet.Kind,
        val balance: Long,
    )

    class State {
        val task = ModelTask()
    }

    class Input(
        today: LocalDate,
    ) {
        var today: LocalDate by mutableStateOf(today)
            internal set

        var list: EntryList? by mutableStateOf(null)
            internal set
    }

    class Output(
        private val input: Input,
    ) {
        val rows: List<Row> by derivedStateOf {
            val list = input.list

            list?.wallets?.values.orEmpty()
                .filter { it.archivedAt == null }
                .sortedBy { it.sortOrder }
                .map { wallet ->
                    Row(
                        id = wallet.id,
                        icon = list?.icons?.get(wallet.iconId),
                        name = wallet.name,
                        kind = wallet.kind,
                        balance = list?.balance(
                            of = wallet,
                            through = input.today,
                        ) ?: 0L,
                    )
                }
        }

        val assets: List<Row>
            get() = rows.filter { !it.kind.isDebt }

        val debts: List<Row>
            get() = rows.filter { it.kind.isDebt }

        val holdings: Holdings
            get() {
                fun total(role: Wallet.Kind.Role): Long =
                    rows.filter { it.kind.role == role }.sumOf { it.balance }

                return Holdings(
                    onHand = total(Wallet.Kind.Role.onHand),
                    cards = total(Wallet.Kind.Role.card),
                    investments = total(Wallet.Kind.Role.investment),
                    loans = total(Wallet.Kind.Role.loan),
                )
            }

        val total: Long
            get() = holdings.available

        val netWorth: Long
            get() = holdings.netWorth
    }

    private class Dependencies(
        val entryList: Flow<EntryList>,
    )

    fun setToday(today: LocalDate) {
        input.today = today
    }

    suspend fun observe() {
        state.task.observe(
            values = dependencies.entryList,
            failure = loadFailedMessage,
        ) { input.list = it }
    }

    companion object {
        const val loadFailedMessage = "残高を読めませんでした"
    }
}
