package com.yossibank.kakeibot.featuremodels.screens.tabs.assets.model

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.isDebt
import com.yossibank.kakeibot.core.concepts.wallet.role
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.queries.types.EntryList
import kotlinx.coroutines.flow.Flow

class AssetsModel(
    entryList: Flow<EntryList>,
) {
    val input = Input()
    val output = Output(input)

    private val dependencies = Dependencies(entryList)

    data class Row(
        val id: Identifier<Wallet>,
        val icon: Icon?,
        val name: String,
        val kind: Wallet.Kind,
        val balance: Long,
    )

    class Input {
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
                        balance = list?.balance(of = wallet) ?: 0L,
                    )
                }
        }

        val assets: List<Row>
            get() = rows.filter { !it.kind.isDebt }

        val debts: List<Row>
            get() = rows.filter { it.kind.isDebt }

        val onHand: Long
            get() = rows.filter { it.kind.role == Wallet.Kind.Role.onHand }.sumOf { it.balance }

        val netWorth: Long
            get() = rows.sumOf { it.balance }
    }

    private class Dependencies(
        val entryList: Flow<EntryList>,
    )

    suspend fun observe() {
        dependencies.entryList.collect { input.list = it }
    }
}
